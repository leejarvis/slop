module Slop
  class Options
    include Enumerable

    DEFAULT_CONFIG = {
      suppress_errors: false,
      type:            "null",
      banner:          true,
    }

    # The Array of Option instances we've created.
    attr_reader :options

    # An Array of separators used for the help text.
    attr_reader :separators

    # Our Parser instance.
    attr_reader :parser

    # A Hash of configuration options.
    attr_reader :config

    # The String banner prefixed to the help string.
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
        separators.last << string
      else
        separators[options.size] = [string]
      end
    end

    def get_separators(i, len, metavar_len, prefix)
      return unless sep = separators[i]
      "#{
      sep.map do |x|
        x.class.superclass == Slop::Option ?
          "#{prefix}#{x.to_s(offset: len, metavar_offset: metavar_len)}" :
          x
      end.join("\n")
      }\n"
    end

    # Add a duplicate option to help
    def help_duplicate(*flags, **config)
      desc = flags.pop unless flags.last.start_with?('-')
      if option = self.options.find {|opt| (flags - opt.flags).empty?}
        klass = option.class unless config[:type]
        config = option.config.merge(config)
        flags = option.flags
        desc ||= option.desc
      else
        config = self.config.merge(config)
        raise ArgumentError, "Options #{flags} do not exist!"\
          unless config[:suppress_errors]
      end
      klass ||= Slop.string_to_option_class(config[:type].to_s)
      dup_option ||= klass.new(flags, desc, config)

      self.separator(dup_option)
    end

    # Sugar to avoid `options.parser.parse(x)`.
    def parse(strings)
      parser.parse(strings)
    end

    # Implements the Enumerable interface.
    def each(&block)
      options.each(&block)
    end

    # Handle custom option types. Will fall back to raising an
    # exception if an option is not defined.
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

    # Return a copy of our options Array.
    def to_a
      options.dup
    end

    # Returns the help text for this options. Used by Result#to_s.
    def to_s(prefix: " " * 4)
      str = config[:banner] ? "#{banner}\n" : ""
      len = longest_flag_length
      metavar_len = longest_metavar_length

      options.select(&:help?).sort_by(&:tail).each_with_index do |opt, i|
        # use the index to fetch an associated separator
        if sep = get_separators(i, len, metavar_len, prefix)
          str << sep
        end

        str << "#{prefix}#{opt.to_s(offset: len, metavar_offset: metavar_len)}\n"

      # add any separators added after the final argument
        if i == (options.select(&:help?).size - 1)
          if sep = get_separators(i + 1, len, metavar_len, prefix)
            str << sep
          end
        end
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

    def longest_metavar_length
      (m = longest_metavar) && m.metavar.length || 0
    end

    def longest_metavar
      options.select(&:expects_argument?).
        max { |a, b| a.metavar.length <=> b.metavar.length }
    end

    def add_option(option)
      options.each do |o|
        flags = o.flags & option.flags

        # Raise an error if we found an existing option with the same
        # flags. I can't immediately see a use case for this..
        if flags.any?
          raise ArgumentError, "duplicate flags: #{flags}"
        end
      end

      options << option
      option
    end
  end
end
