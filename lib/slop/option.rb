class Slop
  class Option

    # @return [String, #to_s] The short flag used for this option
    attr_reader :short_flag

    # @return [String, #to_s] The long flag used for this option
    attr_reader :long_flag

    # @return [String] This options description
    attr_reader :description

    # @return [Proc, #call] The object to execute when this option is used
    attr_reader :callback

    # @return [Boolean] True if the option should be grouped at the
    #   tail of the help list
    attr_reader :tail

    # @return [Regexp] If provided, an options argument **must** match this
    #   regexp, otherwise Slop will raise an InvalidArgumentError
    attr_reader :match

    # @overload argument_value=(value)
    #   Set this options argument value
    attr_writer :argument_value

    # @param [Slop] slop
    # @param [String, #to_s] short
    # @param [String, #to_s] long
    # @param [String] description
    # @param [Boolean] argument
    # @param [Hash] options
    # @option options [Boolean] :optional
    # @option options [Boolean] :argument
    # @option options [Object] :default
    # @option options [Proc, #call] :callback
    # @option options [String, #to_s] :delimiter (',')
    # @option options [Integer] :limit (0)
    # @option options [Boolean] :tail (false)
    # @option options [Regexp] :match
    def initialize(slop, short, long, description, argument, options={}, &blk)
      @slop = slop
      @short_flag = short
      @long_flag = long
      @description = description
      @options = options

      @expects_argument = argument
      @expects_argument = true if options[:optional] == false

      @tail = options[:tail]
      @match = options[:match]

      @forced = false
      @argument_value = nil

      @delimiter = options[:delimiter] || ','
      @limit = options[:limit] || 0

      if @long_flag && @long_flag.size > @slop.longest_flag
        @slop.longest_flag = @long_flag.size
      end

      @callback = blk if block_given?
      @callback ||= options[:callback]
    end

    # @return [Boolean] true if this option expects an argument
    def expects_argument?
      @expects_argument || @options[:argument]
    end

    # @return [Boolean] true if this option accepts an optional argument
    def accepts_optional_argument?
      @options[:optional]
    end

    # @return [String] either the long or short flag for this option
    def key
      @long_flag || @short_flag
    end

    # @return [Object] the argument value after it's been case
    #   according to the `:as` option
    def argument_value
      return @argument_value if @forced
      value = @argument_value || @options[:default]
      return if value.nil?

      case @options[:as].to_s.downcase
      when 'array'
        value.split @delimiter, @limit
      when 'string';  value.to_s
      when 'symbol';  value.to_s.to_sym
      when 'integer'; value.to_s.to_i
      when 'float';   value.to_s.to_f
      else
        value
      end
    end

    # Force an argument value, used when the desired argument value
    # is negative (false or nil)
    #
    # @param [Object] value
    def force_argument_value(value)
      @argument_value = value
      @forced = true
    end

    # @return [Boolean] true if this argument value has been forced
    def forced?
      @forced
    end

    # This option in a nice pretty string, including a short flag, long
    #   flag, and description (if they exist).
    # @see Slop#help
    # @return [String]
    def to_s
      out = "    "
      out += @short_flag ? "-#{@short_flag}, " : ' ' * 4

      if @long_flag
        out += "--#{@long_flag}"
        diff = @slop.longest_flag - @long_flag.size
        spaces = " " * (diff + 6)
        out += spaces
      else
        spaces = " " * (@slop.longest_flag + 8)
        out += spaces
      end

      "#{out}#{@description}"
    end

    # @return [String]
    def inspect
      "#<Slop::Option short_flag=#{@short_flag.inspect} " +
      "long_flag=#{@long_flag.inspect} " +
      "description=#{@description.inspect}>"
    end
  end
end