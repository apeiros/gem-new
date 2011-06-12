class Gem::Commands::NewCommand < Gem::Command
  class Configuration
    def initialize(config_path)
      @config = YAML.load_file(config_path)
    end

    def diff_tool
      @config['diff_tool']
    end

    def content_variables
      @config['content_variables']
    end

    def path_variables
      @config['path_variables']
    end

    def initial_version
      "0.0.1"
    end
  end
end
