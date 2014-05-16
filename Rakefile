require './_build/sheets'
require 'yaml'

class String
  def quote
    '"' + self + '"'
  end
end

class Palettes
  class << self
    def [](name)
      @cache ||= {}
      if @cache.has_key? name
        @cache[name]
      else
        path = palette_path(name)
        if File.file?(path)
          @cache[name] = YAML.load(IO.read(path))
        end
      end
    end
    def palette_path(name)
      File.join("_build", name, "palettes.json")
    end
  end
end

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

  def add_layer(source_prefix, gender)
    layer = Sheet.layer_name(@outpath)
    name = File.basename(@outpath, ".png")
    return if Dir["_build/#{layer}/#{name}/#{source_prefix}*"].empty?

    reference_points_sheet = Sheet.reference_points_sheet @outpath
    rows = reference_points_sheet.frames.group_by {|f| f.row}
    @args << "("
    fullname = "_build/#{layer}/#{name}/#{gender}/#{source_prefix}full.png"
    if File.file?(fullname)
      @args << "#{fullname}[832x1344]"
    else
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
        masks_path.quote,
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
  def replace_color(from, to)
    @args += [
      "-channel", "all",
      "-fill", to,
      "-opaque", from
    ]
  end
end

def hair_base(path, target)
  namespace :hair do
    task :all => target
    task target => [path]
  end
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
    builder.add_layer "bg-", gender
    builder.add_mask "#808080"
    # Behind body
    builder.add_layer "behindbody-", gender
    builder.add_mask "#C0C0C0"
    # Foreground
    builder.add_layer "", gender
    builder.add_mask "#FFFFFF"
    # Remove shadow color
    builder.replace_color "#EAA377", "#00000000"

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
def recolor(type, gender, name)
  palette = Palettes[type]
  base_image_path = "#{type}/#{gender}/#{name}.png"
  recolor_image_directory = "#{type}/#{gender}/#{name}"
  directory recolor_image_directory
  dependencies = FileList.new
  dependencies.add "Rakefile", Palettes.palette_path(type), base_image_path, recolor_image_directory
  palette.keys.each do |palette_name|
    recolor_image_path = "#{recolor_image_directory}/#{palette_name}.png"
    namespace type.to_sym do
      task :all => name.to_sym
      task name.to_sym => recolor_image_path
      file recolor_image_path => dependencies do
        args = [
          "convert",
          base_image_path
        ]
        palette[palette_name].each_pair do |from, to|
          args << "-fill"
          args << to
          args << "-opaque"
          args << from
        end
        args << "+set"
        args << "date:create"
        args << "+set"
        args << "date:modify"
        args << recolor_image_path
        command_line = args.map {|a| '"' + a + '"'}.join(" ")
        sh command_line
      end
    end
  end
end
def hair_and_recolors(type, gender, name)
  hair_base "#{type}/#{gender}/#{name}.png", name.to_sym
  recolor type, gender, name
end
def hair(type, name)
  namespace :hair do
    desc "Generates #{name} hair spritesheet and recolors"
    task name.to_sym
  end
  hair_and_recolors type, "female", name
  hair_and_recolors type, "male", name
end

Dir["_build/hair/*"].each do |dir|
  if File.directory?(dir)
    hair "hair", File.basename(dir)
  end
end
Dir["_build/facial/*"].each do |dir|
  if File.directory?(dir)
    hair "facial", File.basename(dir)
  end
end

namespace :hair do
  desc "Generates all hair spritesheets and recolors"
  task :all
end
namespace :facial do
  desc "Generates all facial spritesheets and recolors"
  task :all
end

desc "Generates all images"
task :default => ["hair:all","facial:all"]