require 'inifile'

module R53z
  class Config
    attr_reader :creds

    def initialize(config_file=nil)
      unless config_file
        # Default to ~/.aws/credentials
        config_file = File.join(ENV['HOME'], ".aws/credentials")
      end
      @creds = IniFile.load(config_file)
    end

    def [](param)
      return self.creds[param]
    end
  end
end

