require "./mp3_to_dca"

# App itself
volume = 1.0
input_path = ""
output_path = ""

# CLI
OptionParser.parse do |parser|
  parser.banner = "Usage: dca [options]"
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit(0)
  end
  parser.on("--version", "Show executable version") do
    puts Mp3ToDca::VERSION
    exit(0)
  end
  parser.on("-v FLOAT", "--volume=FLOAT", "Add volume multiplier (Default: 1.0)") { |val| volume = val.to_f }
  parser.on("-i FILE", "--input=FILE", "Specify input audio file (Default: STDIN)") { |val| input_path = val.to_s }
  parser.on("-o FILE", "--output=FILE", "Name of file to output DCA (DEFAULT: STDOUT)") { |val| output_path = val.to_s }
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end
# Actual encoding
io_i = if input_path.empty?
         STDIN
       else
         File.open(input_path, "r")
       end
io_o = if output_path.empty?
         STDOUT
       else
         File.open(output_path, "w")
       end
Mp3ToDca.encode(io_i, io_o) do |memory|
  unless volume == 1.0
    while memory.peek
      begin
        sample = memory.read_bytes(Int16, IO::ByteFormat::LittleEndian)
        sample = begin
          (sample * volume).to_i16 # This will make sound to 50%
        rescue OverflowError
          sample > 0 ? Int16::MAX : Int16::MIN
        end
        memory.seek(-2, IO::Seek::Current)
        memory.write_bytes(sample, IO::ByteFormat::LittleEndian)
      rescue IO::EOFError
        break
      end
    end
  end
end
