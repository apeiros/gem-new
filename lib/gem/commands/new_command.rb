require 'rubygems/command'
require 'gem/commands/new_command/configuration'
require 'gem/commands/new_command/skeleton'
require 'gem/commands/new_command/version'
require 'fileutils'
require 'open3'



class Gem::Commands::NewCommand < Gem::Command
  ConfigPath          = File.join(Gem.user_home, '.gem', 'new', 'config')
  UserTemplatesDir    = [:user, nil, File.join(Gem.user_home, '.gem', 'new', 'templates')]
  BundledTemplatesDir = [:bundled, nil, Gem.datadir('gem-new')]
  PluginTemplatesDirs = Gem::SourceIndex.from_installed_gems.find_name(/^gem-new-/).map { |spec|
    spec.name
  }.sort.map { |name|
    gem name # load the gem, otherwise Gem.datadir is nil
    [:gem, name, Gem.datadir(name)]
  }
  TemplateDirs        = [UserTemplatesDir] + PluginTemplatesDirs + [BundledTemplatesDir]

  def initialize
    super 'new', "Create a new gem"
    generate_default_config unless File.exist?(ConfigPath)
    add_option('-l', '--list-templates', 'Show a list of all templates') do |value, opts|
      opts[:list_templates] = value
    end
    add_option('-t', '--template TEMPLATE', 'Use TEMPLATE instead of the default template') do |value, opts|
      opts[:template] = value
    end
  end

  def execute
    if options[:list_templates] then
      list_templates
    else
      generate_gem
    end
  rescue
    puts "#{$!.class} #{$!.message}", *$!.backtrace.first(5)
  end

  def arguments # :nodoc:
    "GEMNAME          The name of the gem to generate"
  end

  def usage # :nodoc:
    "#{program_name} GEMNAME"
  end

  def defaults_str # :nodoc:
    ""
  end
  
  def description # :nodoc:
    <<-DESCRIPTION.gsub(/^      /,'').chomp
      Creates the basic directories and files of a new gem for you.
      
      TEMPLATES
      You can provide custom templates in #{UserTemplatesDir}
      To create a template named 'my_template', you'd create the following structure:
      * #{UserTemplatesDir}/
        * my_template/
          * meta.yaml
          * skeleton/
      Within the 'skeleton' directory you place the files and directories for your skeleton.
      Use `#{program_name} GEMNAME --variables` to see what variables are available for paths
      and template-files.

      CONFIGURATION
      You can configure a couple of settings in #{ConfigPath}
    DESCRIPTION
    #'
  end

private
  def templates
    #Dir[template_glob].map { |path| File.basename(path) }.uniq.sort
    seen = {}
    list = []
    TemplateDirs.each do |source_type, source_name, dir|
      Dir.glob(File.join(dir, '*')) do |path|
        name = File.basename(path)
        unless seen[name] then
          list << [source_type, source_name, dir, name]
          seen[name] = true
        end
      end
    end

    list
  end

  def list_templates
    puts "List of available templates (to use with the -t TEMPLATE option):"

    default = Configuration.new(ConfigPath).default_template
    templates.sort_by { |source_type, source_name, dir, name|
      name
    }.each do |source_type, source_name, dir, name|
      default_addon = (default == name) ? ', default' : ''
      case source_type
        when :gem     then puts "- #{name} (from gem '#{source_name}'#{default_addon})"
        when :bundled then puts "- #{name} (bundled with gem-new#{default_addon})"
        when :user    then puts "- #{name} (user template#{default_addon})"
        else raise "Unknown source type #{source_type.inspect}"
      end
    end
  end

  def generate_gem
    gem_name      = get_one_optional_argument
    abort("Must provide a gem name") unless gem_name
    gem_root      = File.expand_path(Dir.getwd)
    gem_path      = File.join(gem_root, gem_name)
    skeleton_name = options[:template] || 'default'
    skeleton_path = template_path(skeleton_name)
    abort("No template named '#{skeleton_name}' found") unless skeleton_path
    skeleton      = Skeleton.new(skeleton_path)
    configuration = Configuration.new(ConfigPath)

    if File.exist?(gem_path) then
      exit unless prompt("A directory '#{gem_path}' already exists, continue?", :no)
      puts "Updating gem '#{gem_name}' in '#{gem_root}"
    else
      puts "Creating gem '#{gem_name}' in '#{gem_root}"
    end

    puts "Using the '#{skeleton_name}' directory skeleton"

    puts "", "Please enter the gem description, terminate with enter and ctrl-d"
    description = $stdin.read
    puts "", "Please enter the gem summary, terminate with enter and ctrl-d"
    summary = $stdin.read
    puts

    now = Time.now
    skeleton.materialize(
      gem_path,
      :path_vars    => symbolize_keys(configuration.path_variables).merge({
        :GEM_NAME     => gem_name,
        :REQUIRE_NAME => gem_name,
        :YEAR         => now.year,
        :MONTH        => now.month,
        :DAY          => now.day,
        :DATE         => now.strftime("%Y-%m-%d"),
      }),
      :content_vars => symbolize_keys(configuration.content_variables).merge({
        :gem_name     => gem_name,
        :require_name => gem_name,
        :now          => now,
        :namespace    => camelcase(gem_name),
        :version      => configuration.initial_version,
        :description  => description,
        :summary      => summary,
        :date         => now.strftime("%Y-%m-%d"),
      })
    ) do |path, new_content|
      old_content = File.read(path)
      next false if old_content == new_content
      result = nil
      while result.nil?
        print("File already exists, replace? ([N]o, [y]es, [d]iff) ")
        $stdout.flush
        case $stdin.gets
          when nil then abort("Terminated")
          when /^y(?:es)?$/i then result = true
          when /^n(?:o)?$/i then result = false
          when /^d(?:iff)?$/i then puts Open3.popen3(configuration.diff_tool % path) { |i,o,e| i.puts new_content; i.close; o.read }
          else puts "Invalid reply"
        end
      end

      result
    end
  end

  def prompt(question, default=:yes)
    print "#{question} #{default == :yes ? '([Y]es, [n]o)' : '([N]o, [y]es)'} "
    $stdout.flush
    if default == :yes then
      $stdin.gets !~ /^n(?:o)?\b/i
    else
      $stdin.gets =~ /^y(?:es)?\b/i
    end
  end

  def generate_default_config
    yaml = <<-YAML.gsub(/^      /, '')
      ---
      # used to migrate configurations automatically
      config_version:   1
      # the template used without -t option
      default_template: default
      # the diff command used to show diffs on update, %s is the path to the old file
      diff_tool:        diff -y --label old --label new %s -
      # whether a diff should be shown right away in updates, without asking first
      auto_diff:        true
      # content variables are used for subsitution in template files, also see path_variables
      content_variables:
        author:         #{ENV["USER"] || 'unknown author'}
        #email:          "your.email@address"
      # content variables are used for subsitution in template paths, also see content_variables
      path_variables: {}
    YAML
    FileUtils.mkdir_p(File.dirname(ConfigPath))
    File.open(ConfigPath, 'wb') { |fh| fh.write(yaml) }
  end

  def template_glob(name='*')
    "{#{TemplateDirs.map { |dir| dir.last }.join(',')}}/#{name}"
  end

  def template_path(name)
    Dir.glob(template_glob(name)) do |path|
      return path
    end
    nil
  end

  def symbolize_keys(hash)
    Hash[hash.map{|k,v|[k.to_sym,v]}]
  end

  def camelcase(string)
    string.gsub(/(?:^|_)([a-z])/) { |m| $1.upcase }
  end
end
