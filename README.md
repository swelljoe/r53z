# R53z

A simple CLI, REPL, and library for managing Route 53. It's primary purpose is to back up and restore Route 53 zones. It can write zones to files in JSON format. It also provides a simple API (not a whole lot easier than the Amazon official API, but for backups and restores, it's much easier to script with and removes tons of boilerplate).

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

You can use the `--section` option to choose which section to use from the credentials file, and the credentials file can be specified with the --credentials option.

```
Usage: r53z [options] [args...]

Simple CLI to manage, backup, and restore, Route 53 zones

v0.1.0

Options:
    -h, --help                       Show command line help
    -x, --export                     Export zones to files in specified directory, optionally specify one or more zones
    -r, --restore                    Restore zone from directory, optionally specify one or more zones
    -l, --list                       List name and ID of one or all zones
    -s, --record-sets                List record sets for the given zone
    -d, --delete                     Delete one or more zone(s) by name (WARNING: No confirmation!)
    -c, --credentials                File containing credentials information
    -u, --section                    Section (user) in the credentials file to use
    -g, --delegation-set ID          Delegation set ID to use for various operations
    -t, --list-delegation-sets       List all delegation sets
    -n, --name-servers ID            List name servers for delegation set
        --version                    Show help/version info
        --log-level LEVEL            Set the logging level
                                     (debug|info|warn|error|fatal)
                                     (Default: info)
```

### Command Line Options

#### --export|-x <path> [zones]

Export one or more zones to the named directory.

Requires a directory path (e.g. /tmp/zonedumps), and optionally one or more zone names. Will export all zones if none specified. If a delegation set ID is given, only zones that share the given delegaion set will be exported.

Two files will be generated in the directory specified, one for the zone metadata (with a zoneinfo.json extension) and the zone records information (with a .json extension).

##### Example

```
$ r53z --export /home/joe/zones swelljoe.com
```

#### --restore|-r <path> [zones]

Restore one or more zones from files in the named directory.

Requires a directory path, and optionally one or more zone names. If no names are given, all files in the directory will be restored. If a delegation set is specified, all zones will be added to the delegation set specified. (The zone info and the record sets don't contain delegation set information, making delegation set selection on restore a little difficult to automate.)

##### Example

```
$ r53z --restore /home/joe/zones swelljoe.com
```

#### --list|-l [--delegation-set ID] [zones]

List hosted zones. List can be restricted to just the listed zones, or to a given delegation set. Output is JSON encoded, and will contain the name and ID of each zone. If no zones are specified, all zones will be listed.

#### --record-sets|-s <zone>

Display the record set

#### --delete|-d <zone>

Delete one or more zones. Argument is the name of the zone, or zones, to delete. This command deletes the record sets for the zone first, and then deletes the zone itself (a zone with records cannot be deleted). There is no confirmation step for this option.

##### Example

```
$ r53z --delete swelljoe.com virtualmin.com
```

#### --credentials|-c <path/filename>

Specify the credentials configuration file on the command line. The file must be an INI file. By default, it will look for a file in ~/.aws/credentials (which is common across several AWS management tools). You can use the `--section` option to choose what section of the file to use.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/swelljoe/r53z.

