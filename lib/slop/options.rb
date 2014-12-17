module Slop
  class Options
    include Enumerable

    DEFAULT_CONFIG = {
      suppress_errors: false,
      type:            "null",
    }

    attr_reader :options
    attr_reader :separators
    attr_reader :parser
    attr_reader :config
    attr_accessor :banner

    def initialize(**config)
      @options    = []
      @separators = []
      @banner     = "usage: #{$0} [options]"
      @config     = DEFAULT_CONFIG.merge(config)
      @parser     = Parser.new(self, @config)

      yield self if block_given?
    end

    # Add a new option. This method is an alias for adding a NullOption
    # (i.e an option with an ignored return value).
    #
    # Example:
    #
    #   opts = Slop.parse do |o|
    #     o.on '--version' do
    #       puts Slop::VERSION
    #     end
    #   end
    #
    #   opts.to_hash #=> {}
    #
    # Returns the newly created Option subclass.
    def on(*flags, **config, &block)
      desc   = flags.pop unless flags.last.start_with?('-')
      config = self.config.merge(config)
      klass  = Slop.string_to_option_class(config[:type].to_s)
      option = klass.new(flags, desc, config, &block)

      add_option option
    end

    # Add a separator between options. Used when displaying
    # the help text.
    def separator(string)
      if separators[options.size]
        separators.last << "\n#{string}"
      else
        separators[options.size] = string
      end
    end

    # Sugar to avoid `options.parser.parse(x)`.
    def parse(strings)
      parser.parse(strings)
    end

    # Implements the Enumerable interface.
    def each(&block)
      options.each(&block)
    end

    def method_missing(name, *args, **config, &block)
      if respond_to_missing?(name)
        config[:type] = name
        on(*args, config, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      Slop.option_defined?(name) || super
    end

    def to_a
      options.dup
    end

    # Returns the help text for this options. Used by Result#to_s.
    def to_s(prefix: " " * 4)
      str = banner + "\n"
      len = longest_flag_length

      options.select(&:help?).each_with_index do |opt, i|
        if sep = separators[i]
          str << "#{sep}\n"
        end
        str << "#{prefix}#{opt.to_s(offset: len)}\n"
      end

      str
    end

    private

    def longest_flag_length
      (o = longest_option) && o.flag.length || 0
    end

    def longest_option
      options.max { |a, b| a.flag.length <=> b.flag.length }
    end

    def add_option(option)
      options.each do |o|
        flags = o.flags & option.flags
        if flags.any?
          raise ArgumentError, "duplicate flags: #{flags}"
        end
      end

      options << option
      option
    end
  end
end
