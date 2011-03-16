class Slop
  class Options < Array
    def to_hash
      each_with_object({}) do |option, out|
        out[option.key] = option.argument_value
      end
    end

    def [](item)
      item = item.to_s
      if item =~ /^\d+/
        super
      else
        find do |option|
          option.short_flag == item || option.long_flag == item
        end
      end
    end
  end

  class Option

    attr_reader :short_flag
    attr_reader :long_flag
    attr_reader :description
    attr_reader :callback
    attr_writer :argument_value

    def initialize(slop, short, long, description, argument, options={}, &block)
      @slop = slop
      @short_flag, @long_flag = short, long
      @description, @expects_argument = description, argument
      @options = options

      if @long_flag && @long_flag.size > @slop.longest_flag
        @slop.longest_flag = @long_flag.size
      end

      @callback = block if block_given?
      @callback ||= options[:callback]
      @argument_value = nil
    end

    def expects_argument?
      @expects_argument || @options[:argument]
    end

    def accepts_optional_argument?
      @options[:optional]
    end

    def has_callback?
      !!@callback && @callback.respond_to?(:call)
    end

    def key
      @long_flag || @short_flag
    end

    def default
      @options[:default]
    end

    def argument_value
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

    def to_s
      out = "    "
      out += @short_flag ?  "-#{@short_flag}, " : ' ' * 4

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
