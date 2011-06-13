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

    def default_template
      @config['default_template']
    end

    def config_version
      @config['config_version']
    end

    def auto_diff
      @config['auto_diff']
    end

    def initial_version
      "0.0.1"
    end
  end
end
