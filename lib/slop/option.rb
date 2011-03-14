class Slop
  class Option

    attr_reader :short_flag
    attr_reader :long_flag
    attr_reader :description

    def initialize(short, long, description, argument, options={}, &block)
      @short_flag, @long_flag = short, long
      @description, @expects_argument = description, argument
      @options = options
      @callback = block if block_given?
      @callback ||= options[:callback]
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

  end
end
