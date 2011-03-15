class Slop
  class Options < Array
    def to_hash
      each_with_object({}) do |option, out|
        out[option.key] = option.argument_value
      end
    end
  end

  class Option

    attr_reader :short_flag
    attr_reader :long_flag
    attr_reader :description
    attr_reader :callback
    attr_writer :argument_value

    def initialize(short, long, description, argument, options={}, &block)
      @short_flag, @long_flag = short, long
      @description, @expects_argument = description, argument
      @options = options

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
      return unless value

      case @options[:as].to_s
      when 'Array'
        value.split(@options[:delimiter] || ',', @options[:limit] || 0)
      when 'String';  value.to_s
      when 'Symbol';  value.to_s.to_sym
      when 'Integer'; value.to_i
      when 'Float';   value.to_f
      else
        value
      end
    end

  end

end
