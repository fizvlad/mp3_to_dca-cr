require "./mp3_to_dca"

# App itself
input_path = "pipe:0"
output_path = "pipe:1"
volume = 1.0
sample_rate = 48000
channels = 2
quiet = false

# CLI
OptionParser.parse do |parser|
  parser.banner = "Usage: dca [options]"
  parser.separator "Data streams:"
  parser.on("-i FILE", "--input=FILE", "Path to input file. If \"pipe:0\" is specified, STDIN will be used") { |val| input_path = val }
  parser.on("-o FILE", "--output=FILE", "Path to output file. If \"pipe:1\" is specified STDOUT will be used") { |val| output_path = val }

  parser.separator ""
  parser.separator "Options:"
  parser.on("-v FLOAT", "--volume=FLOAT", "Volume multiplier (Default: 1.0)") { |val| volume = val.to_f }
  parser.on("-r INTEGER", "--sample-rate=INTEGER", "Sample rate (Default: 48000)") { |val| sample_rate = val.to_i }
  parser.on("-c INTEGER", "--channels=INTEGER", "Amount of channels (Default: 2)") { |val| channels = val.to_i }

  parser.separator ""
  parser.separator "Other:"
  parser.on("--quiet", "Disable log messages (Default: false)") { quiet = true }
  parser.on("--version", "Show executable version") do
    puts Mp3ToDca::VERSION
    exit(0)
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit(0)
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

# Actual encoding
io_i = if input_path == "pipe:0"
         STDIN
       else
         File.open(input_path, "r")
       end
io_o = if output_path == "pipe:1"
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
