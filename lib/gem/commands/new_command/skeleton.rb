require 'erb'
require 'fileutils'
require 'gem/commands/new_command/string_replacer'
require 'gem/commands/new_command/erb_template'



class Gem::Commands::NewCommand < Gem::Command
  # Preregistered processors
  # * .erb:  Interprets the file as ERB template, see rubys stdlib docs on ERB.
  # * .stop: Stops the preprocessing chain, it's advised to add that to all files.
  # * .rb:   Same as .stop
  # * .yaml: Same as .stop
  # * .html: Same as .stop
  # * .js:   Same as .stop
  # * .png:  Same as .stop
  # * .jpg:  Same as .stop
  # * .gif:  Same as .stop
  #   
  class Skeleton
    DefaultOptions  = {
      :verbose  => false,
      :silent   => false,
      :out      => $stdout,
    }
    Processors = {
      '.stop' => nil,
      '.rb'   => nil,
      '.yaml' => nil,
      '.html' => nil,
      '.js'   => nil,
      '.png'  => nil,
      '.jpg'  => nil,
      '.gif'  => nil,
    }
    Processor  = Struct.new(:suffix, :name, :execute)

    def self.register_processor(suffix, name, &execute)
      raise ArgumentError, "A processor named #{suffix.inspect} is already registered" if Processors[suffix]
      raise TypeError, "Processor name must be a String, but is #{suffix.class}:#{suffix.inspect}" unless suffix.is_a?(String)

      Processors[suffix] = Processor.new(suffix, name, execute)
    end

    register_processor '.erb', 'ERB' do |template, variables|
      ErbTemplate.replace(template, variables)
    end

    attr_reader :name
    attr_reader :meta
    attr_reader :base_path
    attr_reader :source_slice
    attr_reader :directories
    attr_reader :files

    def initialize(path, options=nil)
      @name                 = File.basename(path)
      @options              = options ? DefaultOptions.merge(options) : DefaultOptions.dup
      @meta_path            = File.join(path, 'meta.yaml')
      @meta                 = File.exist?(@meta_path) ? YAML.load_file(@meta_path) : {}
      @base_path            = path
      @source_slice         = (path.length+10)..-1
      contents              = Dir[File.join(path, "skeleton", "**", "{*,.gitkeep}")].sort
      @directories, @files  = contents.partition { |path|
        File.directory?(path)
      }
      @verbose              = @options.delete(:verbose)
      @silent               = @options.delete(:silent)
      @out                  = @options.delete(:out)
      raise ArgumentError, "Unknown options: #{@options.keys.join(', ')}" unless @options.empty?
    end

    def includes
      @meta['includes'] || []
    end

    def materialize(in_path, env={}, &on_collision)
      target_slice  = (in_path.length+1)..-1
      path_replacer = StringReplacer.new(env[:path_vars] || {})
      content_vars  = env[:content_vars] || {}

      unless File.exist?(in_path) then
        info "Creating root '#{in_path}'"
        FileUtils.mkdir_p(in_path)
      end

      if @directories.empty? then
        info "No directories to create"
      else
        info "Creating directories"
        @directories.each do |source_dir_path|
          target_dir_path = source_to_target_path(source_dir_path, in_path, path_replacer)
          info "  #{target_dir_path[target_slice]}"
          FileUtils.mkdir_p(target_dir_path)
        end
      end

      if @files.empty? then
        info "No files to create"
      else
        info "Creating files"
        @files.each do |source_file_path|
          target_file_path, processors = source_to_target_path_and_processors(source_file_path, in_path, path_replacer)
          content = processors.inject(File.read(source_file_path)) { |data, processor|
            processor.execute.call(data, content_vars)
          }
          info "  #{target_file_path[target_slice]}"
          if !File.exist?(target_file_path) || (block_given? && yield(target_file_path, content)) then
            File.open(target_file_path, 'wb') do |fh|
              fh.write(content)
            end
          end
        end
      end
    end

    def source_to_target_path(source_path, target_dir, replacer)
      File.join(target_dir, replacer.replace(source_path[@source_slice]))
    end

    def source_to_target_path_and_processors(source_path, target_dir, replacer)
      replaced_source   = replacer.replace(source_path[@source_slice])
      processed_source  = replaced_source.dup
      processors        = []

      while processor = extract_processor_from_path(processed_source)
        processors << processor
      end
      target_path = File.join(target_dir, processed_source)

      [target_path, processors]
    end

  private
    # @param [String] path
    #   The path to extract the processor from.
    #   BEWARE! The string referenced by path will be mutated. The extension is being
    #   removed.
    #
    # @return [Processor, nil]
    #   Returns the processor or nil
    def extract_processor_from_path(path)
      extname   = File.extname(path)
      processor = Processors[extname]
      path.chomp!(extname) if processor

      processor
    end

    def info(msg)
      @out.puts msg unless @silent
    end
    def debug(msg)
      @out.puts msg if @verbose
    end
  end
end
