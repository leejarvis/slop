module Slop
  class Option
    attr_reader :flags, :desc, :config

    def initialize(flags, desc, **config)
      @flags  = flags
      @desc   = desc
      @config = config
    end

    def flag
      flags.join(", ")
    end

    def to_s(offset: 0)
      "%-#{offset}s  %s" % [flag, desc]
    end
  end
end
