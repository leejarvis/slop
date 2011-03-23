class Slop
  class Options < Array

    # @param [Boolean] symbols true to cast hash keys to symbols
    # @return [Hash]
    def to_hash(symbols)
      out = {}
      each do |option|
        key = option.key
        key = key.to_sym if symbols
        out[key] = option.argument_value
      end
      out
    end

    # @param [Object] flag
    # @return [Option] the option assoiated with this flag
    def [](flag)
      item = flag.to_s
      if item =~ /^\d+$/
        slice item.to_i
      else
        find do |option|
          option.short_flag == item || option.long_flag == item
        end
      end
    end

    # @return [String]
    def to_help
      heads = select {|x| !x.tail }
      tails = select {|x| x.tail }
      (heads + tails).map(&:to_s).join("\n")
    end
  end

  class Option

    # @return [String, #to_s]
    attr_reader :short_flag

    # @return [String, #to_s]
    attr_reader :long_flag

    # @return [String]
    attr_reader :description

    # @return [Proc, #call]
    attr_reader :callback

    # @return [Boolean]
    attr_reader :tail

    # @return [Regex]
    attr_reader :match

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
    # @option options [String, #to_s] :delimiter
    # @option options [Integer] :limit
    # @option options [Boolean] :tail
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

      if @long_flag && @long_flag.size > @slop.longest_flag
        @slop.longest_flag = @long_flag.size
      end

      @callback = blk if block_given?
      @callback ||= options[:callback]
      @argument_value = nil
    end

    # @return [Boolean] true if this option expects an argument
    def expects_argument?
      @expects_argument || @options[:argument]
    end

    # @return [Boolean] true if this option expects an optional argument
    def accepts_optional_argument?
      @options[:optional]
    end

    # @return [String] either the long or short flag for this option
    def key
      @long_flag || @short_flag
    end

    # @return [Object]
    def default
      @options[:default]
    end

    # @return [Object] the argument value after it's been case
    #   according to the `:as` option
    def argument_value
      return @argument_value if @forced
      value = @argument_value || default
      return if value.nil?

      case @options[:as].to_s
      when 'Array'
        value.split(@options[:delimiter] || ',', @options[:limit] || 0)
      when 'String';  value.to_s
      when 'Symbol';  value.to_s.to_sym
      when 'Integer'; value.to_s.to_i
      when 'Float';   value.to_s.to_f
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

    def inspect
      "#<Slop::Option short_flag=#{@short_flag.inspect} " +
      "long_flag=#{@long_flag.inspect} " +
      "description=#{@description.inspect}>"
    end
  end
end