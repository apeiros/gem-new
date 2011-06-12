class Gem::Commands::NewCommand < Gem::Command
  class Configuration
    def initialize(config_path)
      @config = YAML.load_file(config_path)
    end

    def diff_tool
      @config['diff_tool']
    end

    def author
      @config['content_variables']['author']
    end

    def initial_version
      "0.0.1"
    end
  end
end
