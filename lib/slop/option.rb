class Slop
  class Option

    # @return [String, #to_s] The short flag used for this option
    attr_reader :short_flag

    # @return [String, #to_s] The long flag used for this option
    attr_reader :long_flag

    # @return [String] This options description
    attr_reader :description

    # @return [Boolean] True if the option should be grouped at the
    #   tail of the help list
    attr_reader :tail

    # @return [Regexp] If provided, an options argument **must** match this
    #   regexp, otherwise Slop will raise an InvalidArgumentError
    attr_reader :match

    # @return [Object] true/false, or an optional help string to append
    attr_reader :help

    # @return [Boolean] true if this options argument value has been forced
    attr_reader :forced

    # @overload argument_value=(value)
    #   Set this options argument value
    #   @param [Object] value The value you'd like applied to this option
    attr_writer :argument_value

    # @return [Integer] The amount of times this option has been invoked
    attr_accessor :count

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
    # @option options [String, #to_s] :unless
    # @option options [Boolean, String] :help (true)
    def initialize(slop, short, long, description, argument, options, &blk)
      @slop = slop
      @short_flag = short
      @long_flag = long
      @description = description
      @argument = argument
      @options = options

      @tail = options[:tail]
      @match = options[:match]
      @delimiter = options.fetch(:delimiter, ',')
      @limit = options.fetch(:limit, 0)
      @help = options.fetch(:help, true)

      @forced = false
      @argument_value = nil
      @count = 0

      @callback = blk if block_given?
      @callback ||= options[:callback]

      build_longest_flag
    end

    # @return [Boolean] true if this option expects an argument
    def expects_argument?
      @argument || @options[:argument] || @options[:optional] == false
    end

    # @return [Boolean] true if this option accepts an optional argument
    def accepts_optional_argument?
      @options[:optional]
    end

    # @return [String] either the long or short flag for this option
    def key
      @long_flag || @short_flag
    end

    # @return [Object] the argument value after it's been cast
    #   according to the `:as` option
    def argument_value
      return @argument_value if @forced
      value = @argument_value || @options[:default]
      return if value.nil?

      case @options[:as].to_s.downcase
      when 'array'
        value.split @delimiter, @limit
      when 'range'
        value_to_range value
      when 'string', 'str';  value.to_s
      when 'symbol', 'sym';  value.to_s.to_sym
      when 'integer', 'int'; value.to_s.to_i
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

    # Execute the block or callback object associated with this Option
    #
    # @param [Object] The object to be sent to `:call`
    def call(obj=nil)
      @callback.call(obj) if @callback.respond_to?(:call)
    end

    # @param [Array] items The original array of objects passed to `Slop.new`
    # @return [Boolean] true if this options `:unless` argument exists
    #   inside *items*
    def omit_exec?(items)
      string = @options[:unless].to_s.sub(/\A--?/, '')
      items.any? { |i| i.to_s.sub(/\A--?/, '') == string }
    end

    # This option in a nice pretty string, including a short flag, long
    # flag, and description (if they exist).
    #
    # @see Slop#help
    # @return [String]
    def to_s
      out = "    "
      out += @short_flag ? "-#{@short_flag}, " : ' ' * 4

      if @long_flag
        out += "--#{@long_flag}"
        if @help.respond_to? :to_str
          out += " #{@help}"
          size = @long_flag.size + @help.size + 1
        else
          size = @long_flag.size
        end
        diff = @slop.longest_flag - size
        out += " " * (diff + 6)
      else
        out += " " * (@slop.longest_flag + 8)
      end

      "#{out}#{@description}"
    end

    # @return [String]
    def inspect
      "#<Slop::Option short_flag=#{@short_flag.inspect} " +
      "long_flag=#{@long_flag.inspect} " +
      "description=#{@description.inspect}>"
    end

    private

    def value_to_range(value)
      case value.to_s
      when /\A(-?\d+?)(?:\.\.|-|,)(-?\d+)\z/
        $1.to_i .. $2.to_i
      when /\A(-?\d+?)\.\.\.(-?\d+)\z/
        $1.to_i ... $2.to_i
      when /\A-?\d+\z/
        value.to_i
      else
        value
      end
    end

    def build_longest_flag
      if @long_flag && @long_flag.size > @slop.longest_flag
        if @help.respond_to? :to_str
          size = @long_flag.size + @help.size
        else
          size = @long_flag.size
        end
        @slop.longest_flag = size
      end
    end
  end
end
