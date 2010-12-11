class Slop
  class Option

    # @return [Symbol,#to_s]
    attr_reader :flag

    # @return [Symbol,#to_s]
    attr_reader :option

    # @return [String]
    attr_reader :description

    # @return [Object]
    attr_reader :default

    # @return [Proc]
    attr_reader :callback

    @@max_option_size = 0

    # @param [Hash] options Option attributes
    # @option options [Symbol,#to_s] :flag
    # @option options [Symbol,#to_s] :option
    # @option options [Symbol,#to_s] :description
    # @option options [Boolean] :argument
    # @option options [Boolean] :optional
    # @option options [Object] :default
    # @option options [Object] :as
    # @option options [Proc] :callback
    # @option options [String,#to_s] :delimiter
    # @option options [Integer] :limit
    def initialize(options={}, &blk)
      @options = options
      @flag = options[:flag]
      @option = options[:option] || options[:opt]
      @description = options[:description] || options[:desc]
      @argument = options[:argument] || false
      @optional = options[:optional] || options[:optional_argument]
      @argument ||= @optional
      @default = options[:default]
      @as = options[:as]
      @callback = options[:callback]

      # Array properties
      @delimiter = options[:delimiter] || ','
      @limit = options[:limit] || 0

      @argument_value = nil

      if @option
        if requires_argument?
          size = (@option.size * 2) + 4
        else
          size = @option.size + 2
        end

        @@max_option_size = size if @@max_option_size < size
      end
    end

    # Set the argument value
    # @param [Object] value
    def argument_value=(value)
      @argument_value = value
    end

    # @return [Object] the argument value after it's been cast
    #   according to the `:as` option
    def argument_value
      @argument_value ||= @default
      return unless @argument_value

      case @as.to_s.downcase[0, 3]
      when 'arr'; @argument_value.split(@delimiter, @limit)
      when 'int'; @argument_value.to_i
      when 'sym'; @argument_value.to_sym
      else
        @argument_value
      end
    end

    # @param [to_s] flag
    # @return [Boolean] true if this option contains a flag
    def has_flag?(flag)
      @flag.to_s == flag.to_s
    end

    # @param [to_s] option
    # @return [Boolean] true if this option contains an option label
    def has_option?(option)
      @option.to_s == option.to_s
    end

    # @return [Boolean] true if this option has a default value
    def has_default?
      !@default.nil?
    end

    # @return [Boolean] true if this option has a switch value
    def has_switch?
      !!@options[:switch]
    end

    # @return [Boolean] true if the option has a callback
    def has_callback?
      !!@callback
    end

    # execute this options callback
    def execute_callback
      @callback.call if has_callback?
    end

    # does the option require an argument?
    # @return [Boolean]
    def requires_argument?
      !!@argument
    end

    # Is the argument optional?
    # @return [Boolean]
    def optional_argument?
      @options[:optional]
    end

    # @return
    def [](key)
      @options[key]
    end

    # Replace options argument value with the switch value supplied, used
    # when supplying the `switch` option making switch flags easy to alter
    #
    # @example
    #   option :v, :verbose, :default => false, :switch => true
    #
    # Now when the `-v` or `--verbose` option is supplied, verbose will
    # be set to `true`, rather than the default `false` option
    def switch_argument_value
      @argument_value = @options[:switch]
    end

    # return a key for an option, prioritize
    # option before flag as it's more descriptive
    def key
      @option || @flag
    end

    def to_s
      str = "\t"

      if @flag
        str << "-#{@flag}"
      else
        str << " " * 4
      end

      if @option
        str << ", " if @flag
        optionstr = "--#{@option}"

        if requires_argument?
          if optional_argument?
            optionstr << " [#{@option}]"
          else
            optionstr << " <#{@option}>"
          end
        end
        size_diff = @@max_option_size - ((@option.size * 2) + 4)
        optionstr << " " * size_diff
        str << optionstr
      else
        str << " " * (@@max_option_size + 2)
      end

      str << "\t#{@description}" if @description
      str
    end

    def inspect
      "#<#{self.class}: #{@options}>"
    end

  end
end