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

      # XXX Dispatch table seems smarter...can't figure out how to call methods based
      # directly on hash keys at the moment.
      if options[:export]
        unless options[:export].is_a? String
          exit_now! "Export must have a valid directory path for dump files."
        end
        unless Dir.exists?(File.expand_path(options[:export]))
          exit_now! "Directory " + options[:export] + " does not exist."
        end
        export(:options => options, :args => args)
      end

      if options[:restore]
        unless Dir.exists?(File.expand_path(options[:restore]))
          exit_now! "Restore requires a directory containing zone files and optionally one or more zones to restore."
        end
        restore(:options => options, :args => args)
      end

      if options[:list]
        list(options: options, args: args)
      end

      if options[:create]
        create(options)
      end

      if options[:delete]
        if args.empty?
          exit_now! "Delete requires one or more zone names."
        end
        args.each do |name|
          if @client.list(name: name).any?
            @client.delete(name)
          else
            exit_now! "Could not locate zone named " + name
          end
        end
      end

      if options['list-delegation-sets']
        delegation_sets(args)
      end

      if options['delete-delegation-sets']
        if args.empty?
          exit_now! "Delete delegation sets requires one or more delegation set IDs."
        end
        args.each do |id|
          @client.delete_delegation_set(id: id)
        end
      end

      if options['record-sets']
        if args.empty?
          exit_now! "List record sets requires one or more zone names."
        end
        record_sets(args)
      end

      if options['name-servers']
        dset = @client.get_delegation_set(options['name-servers'])
        puts JSON.pretty_generate(dset.delegation_set[:name_servers])
      end
    end

    def export(options:, args:)
      path = File.expand_path(options[:export])
      # If no zones, dump all zones
      zones = []
      # One zone, multiple, or all?
      if args.empty?
        @client.list(:delegation_set_id => options['delegation-set']).each do |zone|
          zones.push(zone[:name])
        end
      else
        if options['delegation-set']
          puts "--delegation-set is overridden when one or more zones are provided"
        end
        zones = args
      end

      zones.each do |name|
        @client.dump(path, name)
      end
    end

    def restore(options:, args:)
      path = File.expand_path(options[:restore])
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

      delegation = options['delegation-set'] or nil

      zones.each do |zone|
        @client.restore(path, zone, delegation)
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

    def create(options)
      # Populate a zone hash
      zone_data = {:hosted_zone => { :hosted_zone_config => {}}, :delegation_set =>{}}
      zone_data[:hosted_zone][:name] = options[:create]
      if options[:comment]
        zone_data[:hosted_zone][:config] = {}
        zone_data[:hosted_zone][:config][:comment] = options[:comment]
      end
      if options['delegation-set']
        zone_data[:delegation_set][:id] = options['delegation-set']
      end
      @client.create(info: zone_data)
    end

    def delegation_sets(args)
      # show them all
      if args.empty?
        sets = @client.list_delegation_sets
        sets.each do |set|
          puts JSON.pretty_generate(set.to_h)
        end
      else # only show specified zones
        args.each do |name|
          dset_id = @client.get_delegation_set_id(name)
          if dset_id
            dset = @client.get_delegation_set(dset_id)
            puts JSON.pretty_generate(dset.delegation_set.to_h)
          else
            exit_now!("Could not find a delegation set for " + name)
          end
        end
      end
    end

    def record_sets(args)
      args.each do |name|
        zone_id = @client.get_zone_id(name)
        if zone_id
          sets = @client.list_records(@client.get_zone_id(name))
        else
          exit_now!("Could not locate zone " + name)
        end
        if sets
          puts JSON.pretty_generate(sets)
        else
          exit_now!("Could not locate record list for " + name)
        end
      end
    end
  end
end

