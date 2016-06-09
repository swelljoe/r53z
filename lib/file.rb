require 'json'

# Helper functions for working with JSON files containing resource record sets
module R53z
  # Returns a hash of the contents of named file
  class JsonFile
    def self.read_json(zone_path)
      if zone_path[-5..-1] != '.json'
        zone_path = zone_path + '.json'
      end
      file = File.read(zone_path)
      JSON.load(file)
    end

    def self.write_json(zone_path, zone = {})
      if zone_path[-5..-1] != '.json'
        zone_path = zone_path + '.json'
      end

      File.open(zone_path, 'w') do |f|
        f.write(JSON.pretty_generate(zone))
      end
    end
  end
end

