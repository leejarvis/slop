class Slop
  # Each option specified in `Slop#opt` creates an instance of this class
  class Option < Struct.new(:short_flag, :long_flag, :description, :tail, :match, :help, :required, :forced, :count)

    # @param [Slop] slop The Slop object this Option belongs to
    #
    # @param [String, #to_s] short The short flag representing this Option
    #   without prefix (ie: `a`)
    #
    # @param [String, #to_s] long The long flag representing this Option
    #   without the prefix (ie: `foo`)
    #
    # @param [String] description This options description
    #
    # @param [Boolean] argument True if this option takes an argument
    #
    # @option options [Boolean] :optional
    #   * When true, this option takes an optional argument, ie an argument
    #     does not **have** to be supplied.
    #
    # @option options [Boolean] :argument
    #   * True if this option takes an argument.
    #
    # @option options [Object] :default
    #   * The default value for this option when no argument is given
    #
    # @option options [Proc, #call] :callback
    #   * The callback object, used instead of passing a block to this option
    #
    # @option options [String, #to_s] :delimiter (',')
    #   * A delimiter string when processing this option as a list
    #
    # @option options [Integer] :limit (0)
    #   * A limit, used when processing this option as a list
    #
    # @option options [Boolean] :tail (false)
    #   * When true, this option will be grouped at the bottom of the help
    #     text instead of in order of processing
    #
    # @option options [Regexp] :match
    #   * A regular expression this option should match
    #
    # @option options [String, #to_s] :unless
    #   * Used by `omit_exec` for omitting execution of this options callback
    #     if another option exists
    #
    # @option options [Boolean, String] :help (true)
    #   * If this option is a string, it'll be appended to the long flag
    #     help text (before the description). When false, no help information
    #     will be displayed for this option
    #
    # @option options [Boolean] :required (false)
    #   * When true, this option is considered mandatory. That is, when not
    #     supplied, Slop will raise a `MissingOptionError`
    def initialize(slop, short, long, description, argument, options, &blk)
      @slop = slop

      self.short_flag = short
      self.long_flag = long
      self.description = description

      @argument = argument
      @options = options

      self.tail = @options[:tail]
      self.match = @options[:match]
      self.help = @options.fetch(:help, true)
      self.required = @options[:required]

      @delimiter = @options.fetch(:delimiter, ',')
      @limit = @options.fetch(:limit, 0)
      @argument_type = @options[:as].to_s.downcase
      @argument_value = nil

      self.forced = false
      self.count = 0

      @callback = block_given? ? blk : @options[:callback]

      if long_flag && long_flag.size > @slop.longest_flag
        @slop.longest_flag = long_flag.size
        @slop.longest_flag += help.size if help.respond_to?(:to_str)
      end
    end

    # @return [Boolean] true if this option expects an argument
    def expects_argument?
      @argument || @options[:argument] || @options[:optional] == false
    end

    # @return [Boolean] true if this option accepts an optional argument
    def accepts_optional_argument?
      @options[:optional] || @options[:optional_argument]
    end

    # @return [String] either the long or short flag for this option
    def key
      long_flag || short_flag
    end

    # Set this options argument value.
    #
    # If this options argument type is expected to be an Array, this
    # method will split the value and concat elements into the original
    # argument value
    #
    # @param [Object] value The value to set this options argument to
    def argument_value=(value)
      if @argument_type == 'array'
        @argument_value ||= []

        if value.respond_to?(:to_str)
          @argument_value.concat value.split(@delimiter, @limit)
        end
      else
        @argument_value = value
      end
    end

    # @return [Object] the argument value after it's been cast
    #   according to the `:as` option
    def argument_value
      return @argument_value if forced
      # Check for count first to prefer 0 over nil
      return count if @argument_type == 'count'

      value = @argument_value || @options[:default]
      return if value.nil?

      case @argument_type
      when 'array'
        arg_value(@argument_value)
      when 'range'
        arg_value(value_to_range(value))
      when 'float'
        arg_value(value.to_s.to_f)
      when 'string', 'str'
        arg_value(value.to_s)
      when 'symbol', 'sym'
        arg_value(value.to_s.to_sym)
      when 'integer', 'int'
        arg_value(value.to_s.to_i)
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
      self.forced = true
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
      items.any? do |item|
        item.to_s.sub(/\A--?/, '') == @options[:unless].to_s.sub(/\A--?/, '')
      end
    end

    # This option in a nice pretty string, including a short flag, long
    # flag, and description (if they exist).
    #
    # @see Slop#help
    # @return [String]
    def to_s
      out = "    "
      out += short_flag ? "-#{short_flag}, " : ' ' * 4

      if long_flag
        out += "--#{long_flag}"
        if help.respond_to? :to_str
          out += " #{help}"
          size = long_flag.size + help.size + 1
        else
          size = long_flag.size
        end
        diff = @slop.longest_flag - size
        out += " " * (diff + 6)
      else
        out += " " * (@slop.longest_flag + 8)
      end

      "#{out}#{description}"
    end

    # @return [String]
    def inspect
      "#<Slop::Option short_flag=#{short_flag.inspect} " +
      "long_flag=#{long_flag.inspect} argument=#{@argument.inspect} " +
      "description=#{description.inspect}>"
    end

    private

    def arg_value(value)
      value if accepts_optional_argument? || expects_argument?
    end

    def value_to_range(value)
      case value.to_s
      when /\A(-?\d+?)(\.\.\.?|-|,)(-?\d+)\z/
        Range.new($1.to_i, $3.to_i, $2 == '...')
      when /\A-?\d+\z/
        value.to_i
      else
        value
      end
    end

  end
end