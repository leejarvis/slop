module Slop
  class Option
    attr_reader :flags, :desc, :config

    def initialize(flags, desc, **config)
      @flags  = flags
      @desc   = desc
      @config = config
      @value  = nil
    end

    def call(value)
      @value = value
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
