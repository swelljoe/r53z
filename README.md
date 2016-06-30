# R53z

A simple CLI, REPL, and library for managing Route 53. It's primary purpose is to back up and restore Route 53 zones. It can write zones to files in JSON format. It also provides a simple API (not a whole lot easier than the Amazon official API, but for backups and restores, it's much easier to script with and removes tons of boilerplate).

## Installation

r53z currently requires version 2.1.0 of Ruby, or greater (due to use of named method arguments without default values).

Add this line to your application's Gemfile:

```ruby
gem 'r53z'
```

And then execute:

    $ bundle

Run the command with:

    $ bundle exec bin/r53z

And, you can run a REPL with:

    $ bundle exec bin/console

A `client` object has methods for most common tasks with Route 53, maybe it easy to script with. The REPL is a little clumsy on startup, as it uses the binding method, which gives some clunky output, but it allows setting up both the credentials and client automatically.

Or install it yourself as (the gem installs an r53z executable in the path, but not the `console` REPL):

    $ gem install r53z
    
## Usage

**NOTE:** Don't get too attached to the current CLI options. I'm rewriting the option parser to use sub-commands in the near future. So, if you love it like it is (surely, nobody could love it like it is), you'll need to lock in a version that still has this parser.

Configure a credentials file in `~/.aws/credentials` (this should be an INI file; same as several other AWS utilities expect). It'll look something like this:

```ini
[default]
aws_access_key_id = ACCESS_KEY_ID
aws_secret_access_key = SECRET_ACCESS_KEY
region=us-east-1
```

You can use the `--section` option to choose which section to use from the credentials file, and the credentials file can be specified with the `--credentials` option. Region is irrelevant with Route 53, but the aws-sdk weirdly still requires it be present.

```sh
Usage: r53z [options] [args...]

Simple CLI to manage, backup, and restore, Route 53 zones

v0.3.2

Options:
    -h, --help                       Show command line help
    -x, --export                     Export zones to files in specified directory, optionally specify one or more zones.
    -r, --restore                    Restore zone from directory, optionally specify one or more zones.
    -l, --list                       List name and ID of one or all zones.
    -s, --record-sets                List record sets for the given zone.
    -c, --create NAME                Create a zone with the given name and optional --comment and --delegation-set.
    -n, --comment COMMENT            Optional comment when creating a zone.
    -d, --delete                     Delete one or more zone(s) by name (WARNING: No confirmation!)
    -C, --credentials                File containing credentials information.
    -u, --section                    Section (user) in the credentials file to use.
    -g, --delegation-set ID          Delegation set ID to use for various operations.
    -t, --list-delegation-sets       List delegation set for named zone, or all sets if no zone specified.
    -D, --delete-delegation-sets     Delete one or more delegation sets by ID (WARNING: No confirmation!
    -N, --name-servers ID            List name servers for delegation set.
        --version                    Show help/version info
        --log-level LEVEL            Set the logging level
                                     (debug|info|warn|error|fatal)
                                     (Default: info)

```

### Command Line Options

#### --export|-x {path} [zones]

Export one or more zones to the named directory.

Requires a directory path (e.g. /tmp/zonedumps), and optionally one or more zone names. All zones will be exported if none are specified. If a delegation set ID is given, only zones that share the given delegation set will be exported.

Two files will be generated in the directory specified, one for the zone metadata (with a zoneinfo.json extension) and the zone records information (with a .json extension). The zone metadata file will contain all of the information needed to recreate the zone, incluing the delegation set ID. And, the record set file will contain all of the record sets needed to repopulate the zone; SOA and NS records are not restored as they are defined by the delegation set, rather than by records within the zone.

##### Example

```sh
$ r53z --export /home/joe/zones swelljoe.com
```

#### --restore|-r {path} [zones]

Restore one or more zones from files in the named directory.

Requires a directory path, and optionally one or more zone names. If no names are given, all files in the directory will be restored. If a delegation set is specified, all zones will be added to the delegation set specified. (The zone info and the record sets don't contain delegation set information, making delegation set selection on restore a little difficult to automate.)

If `--delegation-set` is specified on the command line, it will override the delegation-set information provided in the zoneinfo file. This can be used if the delegation set specified in the file is no longer available, for some reason (deletion, migrating to a new account, etc.).

##### Example

```sh
$ r53z --restore /home/joe/zones swelljoe.com
```

#### --list|-l [--delegation-set ID] [zones]

List hosted zones. List can be restricted to just the listed zones, or to a given delegation set. Output is JSON encoded, and will contain the name and ID of each zone. If no zones are specified, all zones will be listed.

#### --create|-c NAME [--comment COMMENT] [--delegation-set ID]

Create zone of the NAME provided. An optional command an delegation set ID may be provided.

##### Example

```sh
$ r53z --create swelljoe.com --comment "My domain"
```

#### --delete|-d {zone}

Delete one or more zones. Argument is the name of the zone, or zones, to delete. This command deletes the record sets for the zone first, and then deletes the zone itself (a zone with records cannot be deleted). There is no confirmation step for this option.

##### Example

```sh
$ r53z --delete swelljoe.com virtualmin.com
```

#### --credentials|-c {path/filename}

Specify the credentials configuration file on the command line. The file must be an INI file. By default, it will look for a file in ~/.aws/credentials (which is common across several AWS management tools). You can use the `--section` option to choose what section of the file to use.

## More Examples

### Working With Delegation Sets

Finding the delegation set of a zone, and backing up all zones that share that delegation set:

```sh
$ r53z --list-delegation-sets swelljoe.com
{
  "id": "/delegationset/NKXKQ56JI1ZGT",
  "caller_reference": "r53z-create-del-set-hh0xf3dm0xp7nuvt",
  "name_servers": [
    "ns-885.awsdns-46.net",
    "ns-2016.awsdns-60.co.uk",
    "ns-417.awsdns-52.com",
    "ns-1299.awsdns-34.org"
  ]
}
$ r53z --export ~/dumps --delegation-set "/delegationset/NKXKQ56JI1ZGT"
```

Creating a new zone with an existing delegation set:

```sh
$ r53z --create swelljoe.com --comment "dootdoot" --delegation-set "/delegationset/NKXKQ56JI1ZGT"
```

Restoring a zone into a specific delegation set (this will override the delegation set specified in the dump file):

```sh
$ r53z --restore ~/dumps swelljoe.com --delegation-set "/delegationset/NKXKQ56JI1ZGT"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

#### Running Tests

To run the full test suite, you need a read/write capable account. There must be a configuration file in `test/data/secret-credentials` containing a `[default]` section with your keys. The format of this file is, as above, a .ini file.

To run all tests:

```sh
$ rake test
```

This will create a few test zones in your account, but unless something goes wrong during the test, they will be removed immediately after, never triggering billing from Amazon. The zones will have somewhat randomly generated names, so they should never clash with existing names (but you may wish to create a non-production account just for testing).

There is one extra tests file called disabled_tc_101.rb. It is disabled, by default, because it takes quite a while to run, especially on a slow link. It produces 101 zones, in order to exercise the list truncation handling code for sets over 100
zones.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/swelljoe/r53z.
