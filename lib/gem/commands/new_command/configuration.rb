class Gem::Commands::NewCommand < Gem::Command
  class Configuration
    def initialize(config_path)
      
    end

    def author
      "Stefan Rusterholz"
    end

    def initial_version
      "0.0.1"
    end
  end
end
