require "json"
require "option_parser"

require "opus-crystal"

# Main module
module Mp3ToDca
  VERSION = "0.1.1"

  # This executable turns audio file into DCA format: https://github.com/bwmarrin/dca#dca
  # Use of this executable requires installed ffmpeg (besides opus ofc).

  # Method which writes DCA metadata to provided `IO`.
  def self.metadata(
    io : IO,
    sample_rate : Int32 = 48000,
    frame_size : Int32 = 960,
    channels : Int32 = 2
  ) : Nil
    json = JSON.build(io) do |json|
      json.object do
        # [REQUIRED] General information about this particular DCA file
        json.field "dca" do
          json.object do
            # [REQUIRED] The version of the metadata and audio format. Changes in this version will always be backwards-compatible
            json.field "version", 1
            # [REQUIRED] Information about the tool used to encode the file
            json.field "tool" do
              json.object do
                # [REQUIRED] Name of the tool, can be any string
                json.field "name", "mp3_to_dca-cr"
                # [REQUIRED] The version of the tool used
                json.field "version", VERSION
                # URL where to find the tool at
                json.field "url", "https://github.com/fizvlad/mp3_to_dca-cr"
                # Author of the tool
                json.field "author", "fizvlad"
              end
            end
          end
        end
        # [REQUIRED] Information about the parameters the audio packets are encoded with
        json.field "opus" do
          json.object do
            # [REQUIRED] The opus mode, also called application - "voip", "music", or "lowdelay"
            json.field "mode", "voip"
            # [REQUIRED] The sample rate in Hz
            json.field "sample_rate", sample_rate
            # [REQUIRED] The frame size in bytes
            json.field "frame_size", frame_size
            # [REQUIRED] The resulting audio bitrate in bits per second, or null if the default has not been changed
            json.field "abr", nil
            # [REQUIRED] Whether variable bitrate encoding has been used (true/false)
            json.field "vbr", true
            # [REQUIRED] The resulting number of audio channels
            json.field "channels", channels
          end
        end
        # Information about the audio track. This attribute is optional but it is highly recommended to add whenever possible
        json.field "info" do
          json.object do
            # Title of the track
            json.field "title", ""
            # Artist who made the track
            json.field "artist", ""
            # Album the track is released in
            json.field "album", ""
            # Genre the track is classified under
            json.field "genre", ""
            # Any comments about the track
            json.field "comments", ""
            # The cover image of the album/track. See footnote [1] for information about this
            json.field "cover", nil
          end
        end
        # Information about where the audio data came from
        json.field "origin" do
          json.object do
            # The type of source that was converted to DCA. See footnote [2] for information about this
            json.field "source", "file"
            # Source bitrate in bits per second
            json.field "abr", nil
            # Number of channels in the source data
            json.field "channels", channels
            # Source encoding
            json.field "encoding", nil
            # The URL the source can be found at, or omitted if it wasn't downloaded from the network. Do not put a file path in here, it should be reserved for remote URLs only
            json.field "url", ""
          end
        end
        # [REQUIRED] A field to put other arbitrary data into. It can be assumed that it always exists, but may be empty. DCA will never use this field internally
        json.field "extra" do
          json.object { }
        end
      end
      # Footnotes for the metadata:
      # The cover image will be a base64-encoded JPEG or PNG image. DCA1 will not
      #   do any differentiation between the two, it is up to the user to read the
      #   respective magic bytes. The image has no size limit, if necessary it can
      #   fill the entire space provided by the maximum length mandated by the metadata
      #   header. If there is no image available, it can be null or the attribute
      #   can be omitted entirely.
      # The source can be any string, but it is suggested to use file if the source
      #   is a local or remote file, and generated if the file has not been converted
      #   in any way but has been generated from scratch using a tool.
    end
  end

  # Method which returns string with DCA metadata.
  def self.metadata(*args, **named_args) : String
    String.build do |str|
      self.metadata(str, *args, **named_args)
    end
  end

  # Reads data from provided `IO` object and print encoded data to output `IO`.
  # Provided block will be yielded with `IO::Memory` containing audio data. This
  # allows you to affect sound in any way you want.
  def self.encode(
    input : IO,
    output : IO,
    sample_rate : Int32 = 48000,
    frame_size : Int32 = 960,
    channels : Int32 = 2,
    &block : IO::Memory -> Nil
  ) : Nil
    # Metadata
    output.print("DCA1")
    meta = self.metadata(sample_rate: sample_rate, frame_size: frame_size, channels: channels)
    output.write_bytes(meta.size.to_i32, IO::ByteFormat::LittleEndian)
    output.print(meta)

    # Audio data
    opus = Opus::Encoder.new(sample_rate, frame_size, channels)
    audio_data = IO::Memory.new # TODO: Might be useful to set some default size
    Process.run(
      "ffmpeg",
      [
        "-i", "pipe:0",
        "-loglevel", "0",
        "-f", "s16le",
        "-ar", sample_rate.to_s,
        "-ac", channels.to_s,
        "pipe:1",
      ],
      shell: true,
      input: input, output: audio_data, error: STDOUT
    )
    audio_data.rewind
    yield audio_data
    audio_data.rewind

    buffer = Bytes.new(opus.input_length)
    while real_length = audio_data.read(buffer)
      break if real_length.zero?
      (real_length...buffer.size).each { |i| buffer[i] = 0 } # Silence
      opus_encoded_data = opus.encode(buffer)
      output.write_bytes(opus_encoded_data.size.to_i16, IO::ByteFormat::LittleEndian)
      output.write(opus_encoded_data)
    end
  end

  # Reads data from provided `IO` object and print encoded data to output `IO`.
  def self.encode(*args, **named_args)
    self.encode(*args, **named_args) {}
  end
end
