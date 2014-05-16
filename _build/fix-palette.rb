PALETTES = {
  'hair' => {
    'ok' => ['#300727', '#6A285E', '#9C5991', '#9C59919C', '#CCA0C5', '#FAF8F9', '#FFFFFF'],
    'map' => {
      '#00000001' => '#00000000', # spurious near-transparent pixels
      '#00000002' => '#00000000',
      '#00000003' => '#00000000',
      '#00000004' => '#00000000',
      '#00000005' => '#00000000',
      '#00000006' => '#00000000',
      '#00000007' => '#00000000',
      '#00000008' => '#00000000',
      '#00000009' => '#00000000',
      '#0000000A' => '#00000000',
      '#0000000B' => '#00000000',
      '#0000000C' => '#00000000',
      '#0000000D' => '#00000000',
      '#0000000E' => '#00000000',
      '#0000000F' => '#00000000',
      '#00000010' => '#00000000',
      '#00000011' => '#00000000',
      '#00000012' => '#00000000',
      '#00000013' => '#00000000',
      '#00000014' => '#00000000',
      '#00000015' => '#00000000',
      '#00000016' => '#00000000',
      '#00000017' => '#00000000',
      '#00000018' => '#00000000',
      '#000000' => '#300727', # eyebrows from 'princess'
      '#2F0926' => '#300727', # slightly-off color from 'longhawk'
      # Standardize on female hair colors. Accordingly, map the male colors
      # (which are on a slightly different scale) to the female palette.
      '#300A27' => '#300727',
      '#6A385E' => '#6A285E',
      '#9B7391' => '#9C5991',
      '#9B73919C' => '#9C59919C',
      '#9B73919E' => '#9C59919C', # incorrect alpha from 'shorthawk'
      '#9B7391DA' => '#9C59919C', # incorrect alpha from one frame of 'shorthawk'
      '#CBB5C5' => '#CCA0C5',
      '#F9F9F9' => '#FAF8F9',
      # Convert from green2 color scheme, for images that don't yet
      # have a base-color image (e.g. 'plain').
      '#01140E' => '#300727',
      '#023E20' => '#6A285E',
      '#027D21' => '#9C5991',
      '#03BC1B' => '#CCA0C5',
      '#03F103' => '#FAF8F9',
      '#98FF75' => '#FFFFFF',
      # Remove extra colors from 'page'
      '#3B1332' => '#300727',
      '#431939' => '#300727',
      '#522548' => '#300727',
      '#6D3B61' => '#6A285E',
      '#7D536A' => '#6A285E',
      '#875B7C' => '#6A285E',
      '#8D6383' => '#6A285E',
      '#946B8A' => '#9C5991',
      '#A07A8E' => '#CCA0C5',
      '#AE8DA5' => '#CCA0C5',
      '#B496AC' => '#CCA0C5',
      '#BB9FB3' => '#CCA0C5',
      '#C1A7BA' => '#CCA0C5',
      '#C7B0C1' => '#CCA0C5',
      '#E6DEE4' => '#CCA0C5',
      '#E8CFE4' => '#CCA0C5',
      '#F2F0F2' => '#FAF8F9',
    }
  }
}

type = ARGV[0]
palette = PALETTES[type]
path = ARGV[1]
if palette.nil? || !File.file?(path)
  puts "Converts a PNG file to use a predefined palette, using predefined rules."
  puts
  puts "Usage:"
  puts "  #{File.basename(__FILE__)} type file.png"
  puts
  puts "Valid values for type:"
  puts PALETTES.keys.sort.map {|name| "  #{name}"}
  exit 1
end

def convert(args)
  `convert #{args.map {|arg| '"' + arg + '"'}.join(' ')}`
end

def unique_colors(args)
  output = convert(args + ['-unique-colors', 'txt:-'])
  output.scan(/#[0-9A-F]+/i)
end

def bad_colors(args, palette)
  unique_colors(args) - palette['ok'] - ['#00000000']
end

if bad_colors([path], palette).empty?
  puts "File '#{path}' already has correct colors for '#{type}'."
  exit 0
end

args = [
  path,
  "-channel", "argb" # allow replacement color to replace alpha channel
]
palette['map'].each do |from, to|
  args += ["-fill", to, "-opaque", from]
end
bad = bad_colors(args, palette)
if bad.any?
  puts "ERROR: The following colors are not valid, and not handled by existing rules:"
  puts bad.map {|color| "  #{color}"}
  exit 1
end

convert(args + ['+set', 'date:create', '+set', 'date:modify', path])
puts "Colors fixed."