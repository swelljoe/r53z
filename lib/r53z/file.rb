require 'json'

# Helper functions for working with JSON files containing resource record sets
module R53z
  # Returns a hash of the contents of named file
  class JsonFile
    include Methadone::Main
    include Methadone::CLILogging

    def self.read_json(path:)
      file = File.read(self.fix_path_json(path))
      parsed = JSON.parse(file)
      # check for aws-cli format and convert
      parsed = self.aws_normalize(parsed)
      return parsed
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

    def self.aws_normalize(json)
      case json
      when Array
        json.each do |k|
          aws_normalize(k)
        end
      when Hash
        json.keys.each do |k|
          value = json.delete(k)
          case value
          when Array
            value = value.map{|v| aws_normalize(v)}
          when Hash
            value = aws_normalize(value)
          when String
            # Time?
            time = time.strptime(value, "%Y-%m-%dT%H:%M:%S.000Z") rescue nil
            value = time if time
          end
          new_key = k
          new_key = Seahorse::Util.underscore(new_key) if new_key.is_a?(String)
          json[new_key.to_sym] = value
        end
      end
      # aws-cli wraps it in a ResourceRecordSets array; we only ever
      # deal with one at a time, so strip it.
      if (json.is_a?(Hash) && json.has_key?(:resource_record_sets))
        json = json[:resource_record_sets]
      end
      json
    end
  end
end
