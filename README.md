# R53z

A simple command line tool for managing Route 53. It's primary purpose is to back up and restore Route 53 zones. It can write zones to files in JSON format. It also provides a simple API (not a whole lot easier than the Amazon official API, but for backups and restores, it's easier to script with).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'r53z'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install r53z

## Usage

Configure a credentials file in ~/.aws/credentials (this should be an INI file; same as several other AWS utilities expect). It'll look something like this:

```ini
[default]
aws_access_key_id = ACCESS_KEY_ID
aws_secret_access_key = SECRET_ACCESS_KEY
region=us-east-1
```

```
Usage: r53z [options] [args...]

Simple CLI to manage Route 53 zones

v0.1.0

Options:
    -h, --help                       Show command line help
    -r, --restore                    Restore zone from FILE(s)
    -e, --export                     Export zones to files in specified directory
    -p, --[no-]pretty                Enable or disable pretty printing
    -l, --list                       List one or all zones by name and ID
                                     (default: true)
    -d, --delete                     Delete ZONE(s) by name
        --version                    Show help/version info
        --log-level LEVEL            Set the logging level
                                     (debug|info|warn|error|fatal)
                                     (Default: info)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/swelljoe/r53z.

