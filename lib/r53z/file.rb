require 'json'

# Helper functions for working with JSON files containing resource record sets
module R53z
  # Returns a hash of the contents of named file
  class JsonFile
    def self.read_json(path:)
      file = File.read(self.fix_path_json(path))
      JSON.parse(file, :symbolize_names => true)
    end

    def self.write_json(path:, data:)
      File.open(self.fix_path_json(path), 'w') do |f|
        f.write(JSON.pretty_generate(data))
      end
    end

    def self.fix_path_json(path)
      unless path[-5..-1] == '.json'
        if path[-1] == '.'
          return path + 'json'
        else
          return path + '.json'
        end
      end
      return path
    end
  end
end

