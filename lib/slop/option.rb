module Slop
  class Option
    DEFAULT_CONFIG = {
      help: true
    }

    attr_reader :flags, :desc, :config, :count, :block
    attr_writer :value

    def initialize(flags, desc, **config, &block)
      @flags  = flags
      @desc   = desc
      @config = DEFAULT_CONFIG.merge(config)
      @block  = block

      reset
    end

    def reset
      @value = nil
      @count = 0
    end

    # Since `call()` can be used/overriden in subclasses, this
    # method is used to do general tasks like increment count. This
    # ensures you don't *have* to call `super` when overriding `call()`.
    # It's used in the Parser.
    def ensure_call(value)
      @count += 1

      if value.nil? && expects_argument? && !suppress_errors?
        raise Slop::MissingArgument, "missing argument for #{flag}"
      end

      @value = call(value)
      block.call(@value) if block.respond_to?(:call)
    end

    def call(_value)
      raise NotImplementedError,
        "you must override the `call' method for option #{self.class}"
    end

    # By default this method does nothing. It's called when all options
    # have been parsed and allows you to mutate the `@value` attribute
    # according to other options.
    def finish(_result)
    end

    # Override this if this option type does not expect an argument
    # (i.e a boolean option type).
    def expects_argument?
      true
    end

    # Override this if you want to ignore the return value for an option
    # (i.e so Result#to_hash does not include it).
    def null?
      false
    end

    def value
      @value || default_value
    end

    def default_value
      config[:default]
    end

    def suppress_errors?
      config[:suppress_errors]
    end

    def flag
      flags.join(", ")
    end

    def key
      (config[:key] || flags.last.sub(/\A--?/, '')).to_sym
    end

    def help?
      config[:help]
    end

    def to_s(offset: 0)
      "%-#{offset}s  %s" % [flag, desc]
    end
  end
end
