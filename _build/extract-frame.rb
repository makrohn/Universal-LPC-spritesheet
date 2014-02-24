require 'fileutils'
require File.join(File.dirname(__FILE__), 'utils.rb')
require File.join(File.dirname(__FILE__), 'sheets.rb')

if ARGV.length < 3
  puts "Usage:"
  puts "  #{File.basename(__FILE__)} spritesheet.png id outfile.png"
  puts "id = the frame's ID number as reported by identify-frames.rb"
  puts "outfile is written as an artifact under _build if no path is given"
  exit 1
end

infile = File.expand_path(ARGV[0])
id = ARGV[1].to_i
layer_name = Sheet.layer_name(infile)
base_dir = File.join(File.dirname(__FILE__), layer_name, File.basename(infile, '.png'))
outfile = File.expand_path(ARGV[2], base_dir)
FileUtils::mkdir_p File.dirname(outfile)
die "File '#{infile}' not found" if !File.file?(infile)

sheet = Sheet[infile]
sheet.fail_if_no_reference_points_sheet
frame = sheet.frames.select {|f| f.id == id}.first
die "Frame ID #{id} not found" if frame.nil?
sheet.save_frame frame, outfile