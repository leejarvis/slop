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

    def value
      @value || config[:default]
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
