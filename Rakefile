require './_build/sheets'

class SheetBuilder
  def initialize(outpath)
    @outpath = outpath
    @layers_added = 0
    @args = [
      # For some reason, when we're reading arguments from a file,
      # we can't have "-background" as the first line in the file,
      # because ImageMagick tries to interpret it as a filename.
      # Adding parentheses works around the problem.
      "(", "-background", "none", ")"
    ]
  end

  def add_layer(source_prefix)
    layer = Sheet.layer_name(@outpath)
    name = File.basename(@outpath, ".png")
    return if Dir["_build/#{layer}/#{name}/#{source_prefix}*"].empty?

    reference_points_sheet = Sheet.reference_points_sheet @outpath
    rows = reference_points_sheet.frames.group_by {|f| f.row}
    @args << "("
    rows.keys.sort.each do |row|
      frames = rows[row]
      @args << "("
      frames.each_with_index do |frame, frame_index|
        basename = "_build/#{layer}/#{name}/#{source_prefix}#{frame.direction}"
        frame_matches = Dir["%s-*%s%X*.png" % [basename, frame.pose.name, frame_index]]
        raise "Multiple matches found: #{frame_matches.join(', ')}" if frame_matches.length > 1
        filename = frame_matches.first || "#{basename}.png"
        if File.file?(filename)
          x = 64 - frame.x
          y = 64 - frame.y
          @args << "#{filename}[64x64+#{x}+#{y}]"
        else
          @args << "xc:none[64x64]"
        end
      end
      @args << "+append"
      @args << ")"
    end
    @args << "-append"
    @args << ")"
    @args << "+repage"

    if @layers_added > 0
      @args += ["-compose", "Over", "-flatten"]
    end
    @layers_added += 1
  end
  def add_mask(mask_color)
    return if @layers_added == 0

    masks_path = Sheet.masks_path @outpath
    if File.file? masks_path
      @args += [
        "(",
        masks_path,
        # Make everything transparent except mask_color
        "+transparent", mask_color,
        ")",
        # Use it as a cutout
        "-compose", "DstOut",
        "-composite"
      ]
    end
  end
  def get_arguments_for_convert
    @args + [
      "+set", "date:create",
      "+set", "date:modify"
    ]
  end
end

def hair_base(path)
  task :hair => [path]
  gender = Sheet.gender_name(path)
  layer = Sheet.layer_name(path)
  name = File.basename(path, ".png")

  dependencies = FileList.new
  dependencies.add "Rakefile", "_build/sheets.rb"
  dependencies.add "_build/#{layer}/#{name}/*.png"
  dependencies.add Sheet.reference_path(path, "*")
  file path => dependencies do
    builder = SheetBuilder.new path
    # Background
    builder.add_layer "bg-"
    builder.add_mask "#808080"
    # Behind body
    builder.add_layer "behindbody-"
    builder.add_mask "#C0C0C0"
    # Foreground
    builder.add_layer ""
    builder.add_mask "#FFFFFF"

    argspath = ".convert-#{layer}-#{gender}-#{name}"
    begin
      File.open argspath, "w" do |argsfile|
        argsfile.puts builder.get_arguments_for_convert.join("\n")
      end
      command_line = %Q|convert "@#{argspath}" "#{path}"|
      sh command_line
    ensure
      File.unlink argspath
    end
  end
end
def hair(type)
  hair_base "hair/female/#{type}.png"
  hair_base "hair/male/#{type}.png"
end
Dir["_build/hair/*"].each do |dir|
  if File.directory?(dir)
    hair File.basename(dir)
  end
end

task :default => [:hair]