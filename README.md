# mp3_to_dca

Executable to convert MP3 audio into DCA format

## Usage

Call `./bin/mp3_to_dca --help` to see usage

Convert example audio: `./bin/mp3_to_dca -i ./data/example.mp3 -o ./data/example.dca`

## Build

Call `crystal build -s -t -p --release ./src/main.cr -o ./bin/mp3_to_dca`

## Contributing

1. Fork it (<https://github.com/fizvlad/mp3_to_dca-cr/fork>)
2. Create your feature branch (`git checkout -b feat/my-new-feature`)
3. Commit your changes (`git commit -am 'feat: add some feature'`)
4. Push to the branch (`git push origin feat/my-new-feature`)
5. Create a new Pull Request

## Contributors

- [fizvlad](https://github.com/fizvlad) - creator and maintainer
