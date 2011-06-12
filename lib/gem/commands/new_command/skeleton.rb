require 'erb'
require 'fileutils'
require 'gem/commands/new_command/string_replacer'
require 'gem/commands/new_command/erb_template'



class Gem::Commands::NewCommand < Gem::Command
  class Skeleton
    DefaultOptions  = {
      :verbose  => false,
      :silent   => false,
      :out      => $stdout,
    }
    Processors = {}
    Processor  = Struct.new(:suffix, :name, :execute)
    
    def self.register_processor(suffix, name, &execute)
      Processors[suffix] = Processor.new(suffix, name, execute)
    end

    register_processor '.literal', 'Literal' do |template, variables|
      template
    end
    register_processor '.erb', 'ERB' do |template, variables|
      ErbTemplate.replace(template, variables)
    end

    attr_reader :meta
    attr_reader :base_path
    attr_reader :source_slice
    attr_reader :directories
    attr_reader :files

    def initialize(path, options=nil)
      @options              = options ? DefaultOptions.merge(options) : DefaultOptions.dup
      @meta                 = YAML.load_file(File.join(path, 'meta.yaml'))
      @base_path            = path
      @source_slice         = (path.length+10)..-1
      contents              = Dir[File.join(path, "skeleton", "**", "{*,.gitkeep}")].sort
      @directories, @files  = contents.partition { |path|
        File.directory?(path)
      }
      @verbose              = @options.delete(:verbose)
      @silent               = @options.delete(:silent)
      @out                  = @options.delete(:out)
    end

    def materialize(in_path, env={})
      target_slice  = (in_path.length+1)..-1
      path_replacer = StringReplacer.new(env[:path_vars] || {})
      content_vars  = env[:content_vars] || {}

      info "Creating directories"
      @directories.each do |source_dir_path|
        target_dir_path = source_to_target_path(source_dir_path, in_path, path_replacer)
        info "  #{target_dir_path[target_slice]}"
        FileUtils.mkdir_p(target_dir_path)
      end

      info "Creating files"
      @files.each do |source_file_path|
        target_file_path, processors = source_to_target_path_and_processors(source_file_path, in_path, path_replacer)
        content = processors.inject(File.read(source_file_path)) { |data, processor|
          processor.execute.call(data, content_vars)
        }
        info "  #{target_file_path[target_slice]}"
        File.open(target_file_path, 'wb') do |fh|
          fh.write(content)
        end
      end
    end

    def source_to_target_path(source_path, target_dir, replacer)
      File.join(target_dir, replacer.replace(source_path[@source_slice]))
    end

    def source_to_target_path_and_processors(source_path, target_dir, replacer)
      replaced_source   = replacer.replace(source_path[@source_slice])
      extname           = File.extname(replaced_source)
      processors        = []
      processed_source  = replaced_source

      if processor = Processors[extname] then
        processors      << processor
        processed_source = processed_source.chomp(extname)
      end
      target_path = File.join(target_dir, processed_source)
#       while processor = Processors[extname]
#         processors       << processor
#         processed_source  = File.basename(processed_source, extname)
#         extname           = File.extname(processed_source)
#       end

      [target_path, processors]
    end

  private
    def info(msg)
      @out.puts msg unless @silent
    end
    def debug(msg)
      @out.puts msg if @verbose
    end
  end
end
