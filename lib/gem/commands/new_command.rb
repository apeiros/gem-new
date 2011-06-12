require 'rubygems/command'
require 'gem/commands/new_command/configuration'
require 'gem/commands/new_command/skeleton'
require 'gem/commands/new_command/version'



class Gem::Commands::NewCommand < Gem::Command
  UserTemplatesDir    = File.expand_path(File.join(Gem.user_home, '.gem/new'))
  BundledTemplatesDir = File.expand_path(File.join(Gem.datadir('gem-new')))
  TemplateDirs = [
    UserTemplatesDir,
    BundledTemplatesDir,
  ]

  def initialize
    super 'new', "Create a new gem"
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
    config_path   = File.join(Gem.user_home, '.gem_new_config')
    gem_name      = get_one_optional_argument
    abort("Must provide a gem name") unless gem_name
    gem_root      = File.expand_path(Dir.getwd)
    gem_path      = File.join(gem_root, gem_name)
    skeleton_name = options[:template] || 'default'
    skeleton_path = template_path(skeleton_name)
    abort("No template named '#{skeleton_name}' found") unless skeleton_path
    skeleton      = Skeleton.new(skeleton_path)
    configuration = Configuration.new(config_path)

    puts "Creating gem '#{gem_name}' in '#{gem_root}"
    puts "Using the '#{skeleton_name}' directory skeleton"

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
    )
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
