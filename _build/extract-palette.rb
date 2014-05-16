require 'json'

def print_usage_and_exit
  puts "Usage:"
  puts
  puts "  #{File.basename(__FILE__)} base-color-sheet.png recolor-sheet.png [...]"
  puts "You can specify multiple recolor sheets."
  puts
  puts "  #{File.basename(__FILE__)} name"
  puts "This uses name.png as the base color sheet, and name/*.png as recolor sheets."
  puts
  puts "The output is JSON describing how colors from base-color-sheet map to colors"
  puts "from recolor-sheet."
  exit 1
end

def parse_colors(command_line_output, ignore_colors = [])
  # Return all the unique colors in the file, ignoring transparent
  result = []
  command_line_output.lines.each do |line|
    next if line =~ /^#/
    if line =~ /#[0-9A-F]{6}([0-9A-F]{2})?\b/i
      color_name = $&
      result << color_name unless ignore_colors.include?(color_name)
    end
  end
  result
end

def get_unique_colors(path)
  parse_colors `convert "#{path}" -unique-colors txt:-`, ['#00000000']
end

def get_colors_by_color_mask(image_path, mask_image_path, mask_color)
  # Gets all the unique colors in image_path from the locations
  # that match mask_color in mask_image_path
  args = [
    image_path,
    "(",
    mask_image_path,
    "+transparent", mask_color,
    ")",
    "-compose", "DstIn",
    "-composite",
    "-unique-colors"
  ]
  argspath = ".convert-colors-#{File.basename(image_path)}"
  begin
    File.open argspath, "w" do |argsfile|
      argsfile.puts args.join("\n")
    end
    command_line = %Q|convert "@#{argspath}" txt:-|
    result = parse_colors `#{command_line}`, ['#00000000']
  ensure
    File.unlink argspath
  end
  result
end

def print_recolors(base_color_path, recolor_paths)
  results = []
  colors = get_unique_colors(base_color_path)
  recolor_paths.each_with_index do |recolor_path, index|
    if recolor_paths.length > 1
      STDERR.puts "Reading #{recolor_path} (#{index + 1} of #{recolor_paths.length})..."
    end
    colormap = {}
    colors.each do |source_color|
      target_colors = get_colors_by_color_mask(recolor_path, base_color_path, source_color)
      if target_colors.length != 1
        STDERR.puts "WARNING: #{recolor_path}: " +
          "Expected unique replacement color for #{source_color}, " +
          "but found #{target_colors}"
      end
      colormap[source_color] = target_colors[0]
    end
    recolor_name = File.basename(recolor_path, '.png')
    results << {recolor_name => colormap}.to_json
  end
  puts "// #{File.basename(base_color_path, '.png')}"
  puts "{"
  print "  "
  puts results.join(",\n  ")
  puts "}"
end

if ARGV.length == 1 && File.directory?(ARGV[0])
  base_color_path = "#{ARGV[0]}.png"
  recolor_glob = File.join(ARGV[0], "*.png")
  recolor_paths = Dir[recolor_glob]
  if recolor_paths.empty?
    STDERR.puts "#{recolor_glob}: No matching files"
    print_usage_and_exit
  end
  print_recolors base_color_path, recolor_paths
elsif ARGV.length > 1 && File.file?(ARGV[0])
  base_color_path = ARGV[0]
  recolor_paths = ARGV.drop(1)
  print_recolors base_color_path, recolor_paths
else
  print_usage_and_exit
end