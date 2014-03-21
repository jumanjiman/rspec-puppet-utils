require 'hieradata/validator'
require 'yaml'

module RSpecPuppetUtils
  module HieraData

    # only load data once (performance)
    # tests can run independently and do not require a "load" test
    # syntax errors (or empty files) should be caught in a test, not blow up in a describe or context block
    # all errors are easy to find

    #validator = HieraData::YamlValidator.new('spec/fixtures/hieradata', ['eyaml'])
    #validator.load_data :ignore_empty

    class YamlValidator < HieraData::Validator

      def initialize(directory, extensions = ['yaml', 'yml'])
        raise ArgumentError, 'extensions should be an Array' unless extensions.is_a? Array
        @directory = directory
        @extensions = extensions.map {|ext| ext =~ /\..*/ ? ext : ".#{ext}" }
      end

      def load_data(*args)
        @load_errors = []
        @data = {}
        files = find_yaml_files
        files.each { |file| load_data_for_file file, args.include?(:ignore_empty) }
        self
      end

      # Deprecated - delete soon!
      def load(ignore_empty = false)
        warn '#load is deprecated, use #load_data instead'
        ignore_empty ? load_data(:ignore_empty) : load_data
        raise ValidationError, @load_errors[0] unless @load_errors.empty?
      end

      private

      def load_data_for_file(file, ignore_empty)
        # Assume all file names are unique i.e. thing.yaml and thing.yml don't both exist
        file_name = File.basename(file).split('.').first
        begin
          yaml = File.open(file) { |yf| YAML::load( yf ) }
        rescue ArgumentError => e
          @load_errors.push "Error in file #{file}: #{e.message}"
          return
        end
        @load_errors.push "Yaml file is empty: #{file}" unless yaml || ignore_empty
        @data[file_name.to_sym] = yaml if yaml
      end

      def find_yaml_files
        Dir.glob(File.join(@directory, '**', '*')).reject { |path|
          File.directory?(path) || !@extensions.include?(File.extname path )
        }
      end

    end

  end
end
