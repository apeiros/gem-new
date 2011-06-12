require 'rubygems/command'
require 'gem/commands/new_command/configuration'
require 'gem/commands/new_command/skeleton'
require 'gem/commands/new_command/version'
require 'fileutils'
require 'open3'



class Gem::Commands::NewCommand < Gem::Command
  ConfigPath          = File.join(Gem.user_home, '.gem', 'new', 'config')
  UserTemplatesDir    = File.expand_path(File.join(Gem.user_home, '.gem', 'new', 'templates'))
  BundledTemplatesDir = File.expand_path(File.join(Gem.datadir('gem-new')))
  TemplateDirs = [
    UserTemplatesDir,
    BundledTemplatesDir,
  ]


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

      CONFIGURATION
      You can configure a couple of settings in #{ConfigPath}
    DESCRIPTION
  end

private
  def list_templates
    puts "List of available templates (to use with the -t TEMPLATE option):"
    Dir[template_glob].map { |path| File.basename(path) }.uniq.sort.each do |template|
      puts "- #{template}"
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

    puts "Creating gem '#{gem_name}' in '#{gem_root}"
    puts "Using the '#{skeleton_name}' directory skeleton"

    if File.exist?(gem_path) then
      exit unless prompt("A directory '#{gem_path}' already exists, continue?", :no)
    end

    puts "", "Please enter the gem description, terminate with enter and ctrl-d"
    description = $stdin.read
    puts "", "Please enter the gem summary, terminate with enter and ctrl-d"
    summary = $stdin.read
    puts

    skeleton.materialize(
      gem_path,
      :path_vars    => {
        :GEM_NAME     => gem_name,
        :REQUIRE_NAME => gem_name
      },
      :content_vars => {
        :gem_name     => gem_name,
        :require_name => gem_name,
        :namespace    => camelcase(gem_name),
        :author       => configuration.author,
        :version      => configuration.initial_version,
        :description  => description,
        :summary      => summary,
      }
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
      config_version: 1
      diff_tool:      diff -y --label old --label new %s -
      # content variables are used for subsitution in template files, also see path_variables
      content_variables:
        author:         #{ENV["USER"] || 'unknown author'}
      # content variables are used for subsitution in template paths, also see content_variables
      path_variables: {}
    YAML
    FileUtils.mkdir_p(File.dirname(ConfigPath))
    File.open(ConfigPath, 'wb') { |fh| fh.write(yaml) }
  end

  def template_glob(name='*')
    "{#{TemplateDirs.join(',')}}/#{name}"
  end

  def template_path(name)
    Dir.glob(template_glob(name)) do |path|
      return path
    end
    nil
  end

  def camelcase(string)
    string.gsub(/(?:^|_)([a-z])/) { |m| $1.upcase }
  end
end