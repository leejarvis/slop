class Slop
  class Option

    StringProcessor   = proc { |v| v.to_s }
    SymbolProcessor   = proc { |v| v.to_sym }
    IntegerProcessor  = proc { |v| v.to_s.to_i }
    FloatProcessor    = proc { |v| v.to_s.to_f }
    ArrayProcessor    = proc { |v, o|
      v.split(o.config[:delimiter], o.config[:limit])
    }

    class RangeProcessor
      def self.call(value, _option)
        case value.to_s
        when /\A(\-?\d+)\z/
          Range.new($1.to_i, $1.to_i)
        when /\A(-?\d+?)(\.\.\.?|-|,)(-?\d+)\z/
          Range.new($1.to_i, $3.to_i, $2 == '...')
        end
      end
    end

    def self.build(command, args, &block)
      OptionBuilder.build(command, args, &block)
    end

    class << self
      attr_accessor :default_config
    end

    self.default_config = {
      argument:           false,
      optional_argument:  false,
      default:            nil,
      as:                 String,
      delimiter:          ',',
      limit:              0,
    }

    attr_reader :command, :short, :long, :description, :config, :runner, :count
    attr_writer :value

    # command     - The Slop::Command that owns this option.
    # short       - The short flag (minus any prefixes).
    # long        - The long flag (minus any prefixes).
    # description - The description text for this option.
    # config      - An optional Hash of configuration options.
    # block       - A block to be called when `call` is executed.
    def initialize(command, short, long, description, config, &block)
      @command     = command
      @short       = short
      @long        = long
      @description = description
      @config      = Option.default_config.merge(config)
      @runner      = config.fetch(:runner, block)
      @value       = nil
      @count       = 0
    end

    # Returns true if this option excepts an argument.
    def argument?
      config[:argument]
    end

    # Returns true if this option accepts an optional argument.
    def optional_argument?
      config[:optional_argument]
    end

    def value
      return config[:default] unless @value
      process_value(@value)
    end

    # Call this option.
    #
    # Returns the value of this option.
    def call
      runner.call(value) if runner.respond_to?(:call)
      value
    end

    # Executes `call` and increments option count.
    def execute
      call
      @count += 1
    end

    # Returns either the long or short flag for this option.
    def key
      long || short
    end

    # Returns the help output for this option.
    def help
      ""
    end

    alias_method :to_s, :help

    private

    def process_value(value)
      as = config[:as]
      as = string_to_processor(as) unless as.respond_to?(:call)
      as.call(value, self)
    end

    private

    def string_to_processor(string)
      Option.const_get("#{string}Processor")
    rescue NameError
      StringProcessor
    end

  end
end
