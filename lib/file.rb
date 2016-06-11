require 'json'

# Helper functions for working with JSON files containing resource record sets
module R53z
  # Returns a hash of the contents of named file
  class JsonFile
    def self.read_json(path:)
      if path[-5..-1] != '.json'
        path = path + '.json'
      end
      file = File.read(path)
      JSON.load(file)
    end

    def self.write_json(path:, data:)
      if path[-5..-1] != '.json'
        path = path + '.json'
      end

      File.open(path, 'w') do |f|
        f.write(JSON.pretty_generate(data))
      end
    end
  end
end

