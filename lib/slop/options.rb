module Slop
  class Options
    attr_reader :options
    attr_accessor :banner

    def initialize
      @options = []
      @banner  = "usage: #{$0} [options]"
    end

    def add(*flags, **config)
      desc   = flags.pop unless flags.last.start_with?('-')
      type   = config.delete(:type) || "string"
      klass  = Slop.string_to_option_class(type.to_s)
      option = klass.new(flags, desc, config)

      add_option option
    end

    def method_missing(name, *args, **config, &block)
      if respond_to_missing?(name)
        config[:type] = name
        add(*args, config, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      Slop.option_defined?(name) || super
    end

    def to_a
      options.dup
    end

    private

    def add_option(option)
      options.each do |o|
        flags = o.flags & option.flags
        if flags.any?
          raise ArgumentError, "duplicate flags: #{flags}"
        end
      end

      options << option
      option
    end
  end
end
