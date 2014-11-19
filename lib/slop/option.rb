module Slop
  class Option
    attr_reader :flags, :desc, :config, :count

    def initialize(flags, desc, **config)
      @flags  = flags
      @desc   = desc
      @config = config

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
    end

    def call(value)
      raise NotImplementedError,
        "you must override the `call' method for option #{self.class}"
    end

    def value
      @value
    end

    def flag
      flags.join(", ")
    end

    def key
      (config[:key] || flags.last.sub(/\A--?/, '')).to_sym
    end

    def to_s(offset: 0)
      "%-#{offset}s  %s" % [flag, desc]
    end
  end
end
