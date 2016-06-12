require 'json'

module R53z
  class Cli
    def initialize(options:, args:)
      section = options[:section] || 'default'
      config_file = options[:credentials]
      creds = R53z::Config.new(config_file)
      @client = R53z::Client.new(section, creds)

      if options[:export]
        help_now! "Export requires a directory path for zone files" if args.length < 1
        export(:options => options, :args => args)
      end

      if options[:restore]
        help_now! "Restore requires one or more files to restore (don't include file extensions)" if args.empty?
        restore(:options => options, :args => args)
      end

      if options[:list]
        self.list(options: options, args: args)
      end
    end

    def export(options:, args:)
      path = args.shift
      # If no zones, dump all zones
      puts args.length
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

    def list(options:, args:)
      if args.any?
        args.each do |name|
          puts JSON.pretty_generate(@client.list(:name => name))
        end
      else
        puts JSON.pretty_generate(@client.list)
      end
    end
  end
end

