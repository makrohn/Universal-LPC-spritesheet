# A Sheet instance represents an entire spritesheet, the images in it, a
# unique ID for each distinct arrangement of pixels (ignoring the offset from
# the origin), and the X/Y offset relative to a known reference point (e.g.
# for hair images, the head is used as the reference point).
#
# Sheet[path]
#   Returns the sheet for the given image file, with reference points loaded.
#   Raises an error if the path doesn't exist.
# Sheet.find(path)
#   Same as [], but returns nil if the file doesn't exist.
# Sheet#frames
#   List of Frame objects, one for every animation frame in the spritesheet.

require 'digest'
require File.join(File.dirname(__FILE__), 'utils.rb')

class Pose < Struct.new(:name, :row, :cols, :directions)
  def rows
    self.directions.length
  end
end

class Frame < Struct.new(:row, :col, :pose, :direction, :x, :y, :width, :height, :reference_frame, :id)
  def to_s
    "#{id} #{x},#{y} #{width}x#{height} R#{row}C#{col} #{pose.name}/#{direction}"
  end
end

class Sheet
  POSES = [
    Pose.new("spellcast", 0, 7, "nwse"),
    Pose.new("thrust", 4, 8, "nwse"),
    Pose.new("walkcycle", 8, 9, "nwse"),
    Pose.new("slash", 12, 6, "nwse"),
    Pose.new("shoot", 16, 13, "nwse"),
    Pose.new("hurt", 20, 6, "s")
  ]

  def initialize(path, reference_points_sheet = nil)
    @path = path
    @reference_points_sheet = reference_points_sheet
    @reference_frames = (reference_points_sheet.frames.dup if reference_points_sheet) || []
  end

  attr_reader :frames
  attr_reader :path

  def build_command_line
    args = ["convert"]
    POSES.each do |r|
      # Add the source image cropped to this pose
      args << "#{@path}[#{r.cols*64}x#{r.rows*64}+0+#{r.row*64}]"
    end
    args += [
      # Forget each image's original origin
      "+repage",
      # Crop the images into a series of 64x64 frames
      "-crop", "64x64",
      # Forget each frame's original origin
      "+repage",
      # Trim all transparent pixels from the outside of the image. ImageMagick
      # doesn't let us specify what color to trim, it just uses the outermost
      # color, so start by adding a transparent border to ensure it trims
      # transparent pixels.
      "-bordercolor", "none",
      "-border", "1x1",
      "-trim",
      # Write textual metadata to STDOUT, one line per frame. This operation
      # completes before we continue, so the output has all metadata first,
      # followed by all pixel data. Output is the X and Y offsets of the
      # center non-transparent portion of the image, and its width and height.
      "-format", "%X %Y %w %h\\n",
      "-write", "info:-",
      # Write pixel data to STDOUT. We can use the metadata to determine how
      # many pixels were written for each frame. This is only the center
      # non-transparent portion of the image, so we can MD5-hash it to identify
      # unique frames regardless of offset.
      "+repage",
      "rgba:-"
    ]
    args.map {|a| '"' + a + '"'}.join(" ")
  end
  def fail_if_no_reference_points_sheet
    if @reference_points_sheet.nil?
      die "No reference-point image was found."
    end
  end
  def load
    hashes = {}
    IO.popen(build_command_line, "rb") do |p|
      # The "convert" command outputs metadata first...
      @frames = []
      POSES.each do |pose|
        pose.directions.chars.each_with_index do |direction, row_within_pose|
          row = pose.row + row_within_pose
          0.upto(pose.cols - 1) do |col|
            x, y, width, height = p.readline.split(' ').map {|v| v.to_i}
            # Offsets reported by ImageMagick include the 1-pixel safety border we added
            x -= 1
            y -= 1
            reference_frame = @reference_frames.shift
            if reference_frame
              x -= reference_frame.x
              y -= reference_frame.y
            end
            @frames << Frame.new(row, col, pose, direction, x, y, width, height, reference_frame)
          end
        end
      end
      # ...followed by data
      @frames.each do |frame|
        content = p.read frame.width * frame.height * 4
        hash = Digest::MD5.hexdigest content
        if !hashes.key?(hash)
          hashes[hash] = hashes.length
        end
        frame.id = hashes[hash]
      end
    end
    self
  end
  def print_frames
    puts "Frames:"
    @frames.group_by {|f| f.row}.each do |row, frames|
      print "R#{row} (#{frames[0].pose.name}/#{frames[0].direction}): "
      ids = frames.map {|f| f.id}
      if ids.min == ids.max
        puts "#{ids.min} (x#{ids.length})"
      else
        puts ids.join(' ')
      end
    end
    puts
  end
  def print_offset_histogram
    if @reference_points_sheet
      puts "Offsets of each unique frame (relative to reference points):"
    else
      puts "Offsets of each unique frame (relative to origin):"
    end
    puts "Frame ID: offset, count, (locations of outliers)"
    ids = {}
    @frames.each do |frame|
      id_data = (ids[frame.id] ||= {})
      offset = "#{frame.x},#{frame.y}"
      id_data[offset] ||= 0
      id_data[offset] += 1
    end
    ids.keys.sort.each do |id|
      print "%2d: " % id
      id_data = ids[id]
      id_data.keys.sort_by {|key| -id_data[key]}.each_with_index do |key, index|
        print '    ' if index > 0
        print "#{key} x#{id_data[key]}"
        if index > 0
          print " ("
          print @frames.select {|f| f.id == id && key == "#{f.x},#{f.y}"}.map {|f| "R#{f.row}C#{f.col}"}.join(', ')
          print ")"
        end
        puts
      end
    end
    puts
  end
  def save_frame(frame, outfile)
    delta_x = 64 - frame.reference_frame.x
    delta_y = 64 - frame.reference_frame.y
    args = [
      "convert",
      "#{@path}[64x64+#{frame.col*64}+#{frame.row*64}]",
      "-repage", "128x128+#{delta_x}+#{delta_y}",
      "-background", "none",
      "-flatten",
      outfile
    ]
    command_line = args.map {|a| '"' + a + '"'}.join(" ")
    system command_line
  end
  def warn_if_no_reference_points_sheet
    if @reference_points_sheet.nil?
      puts "No reference-point image was found. Offsets are relative to the origin."
    end
  end

  class << self
    def [](path)
      raise "File '#{path}' not found" if !File.file? path
      find path
    end
    def dir(path)
      if File.directory?(path)
        path
      else
        File.dirname(path)
      end
    end
    def find(path)
      return nil if !File.file?(path)
      @loaded_sheets ||= {}
      path = File.expand_path path
      @loaded_sheets[path] ||= load(path, find_reference_points_sheet(path))
    end
    def find_reference_points_sheet(infile)
      find reference_points_path infile
    end
    def gender_name(path)
      /\b(fe)?male\b/.match(path).to_s
    end
    def layer_name(path)
      /\b(hair|facial)\b/.match(dir(path)).to_s
    end
    def load(path, reference_points_sheet = nil)
      Sheet.new(path, reference_points_sheet).load
    end
    def masks_path(infile)
      reference_path infile, "masks"
    end
    def reference_path(infile, basename)
      gender = gender_name(infile)
      layer = layer_name(infile)
      reference_filename = "#{layer}/#{basename}_#{gender}.png"
      File.join(File.dirname(__FILE__), reference_filename)
    end
    def reference_points_path(infile)
      reference_path infile, "reference_points"
    end
    def reference_points_sheet(infile)
      self[reference_points_path infile]
    end
  end
end