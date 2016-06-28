require 'json'

module R53z
  class Cli
    include Methadone::Main
    include Methadone::CLILogging

    def initialize(options:, args:)
      section = options[:section] || 'default'
      config_file = options[:credentials]
      creds = R53z::Config.new(config_file)
      @client = R53z::Client.new(section, creds)

      # XXX Dispath table seems smarter...can't figure out how to calls methods based
      # directly on hash keys at the moment.
      if options[:export]
        help_now! "Export requires a directory path for zone files" if args.length < 1
        export(:options => options, :args => args)
      end

      if options[:restore]
        if args.empty?
          help_now! "Restore requires a directory containing zone files and optionally one or more zones to restore"
        end
        restore(:options => options, :args => args)
      end

      if options[:list]
        list(options: options, args: args)
      end

      if options[:delete]
        if args.empty?
          help_now! "Delete requires one or more zone names"
        end
        args.each do |name|
          @client.delete(name)
        end
      end

      if options['list-delegation-sets']
        sets = @client.list_delegation_sets
        sets.each do |set|
          puts JSON.pretty_generate(set.to_h)
        end
      end

      if options['record-sets']
        if args.empty?
          help_now! "List record sets requires one or more zone names"
        end
        args.each do |name|
          sets = @client.record_list(@client.get_zone_id(name))
          puts JSON.pretty_generate(sets)
        end
      end

      if options['name-servers']
        dset = @client.get_delegation_set(id: options['name-servers'])
        puts JSON.pretty_generate(dset.delegation_set[:name_servers])
      end
    end

    def export(options:, args:)
      path = args.shift
      # If no zones, dump all zones
      zones = []
      # One zone, multiple, or all?
      if args.empty?
        @client.list.each do |zone|
          zones.push(zone[:name])
        end
      else
        zones = args
      end

      zones.each do |name|
        @client.dump(path, name)
      end
    end

    def restore(options:, args:)
      path = args.shift
      # If no zones, restore all zones in directory
      zones = []
      if args.empty?
        # derive list of zones from files in path
        zones = Dir[File.join(path, "*.json")].reject {|n| n.match("zoneinfo")}
      else
        # restore the ones specified
        args.each do |zone|
          zones.push(zone)
        end
      end

      zones.each do |zone|
        @client.restore(path, zone)
      end
    end

    def list(options:, args:)
      if args.any?
        args.each do |name|
          puts JSON.pretty_generate(
            @client.list(
              :name => name,
              :delegation_set_id => options['delegation-set']))
        end
      else
        puts JSON.pretty_generate(
          @client.list(:delegation_set_id => options['delegation-set'])
        )
      end
    end
  end
end

