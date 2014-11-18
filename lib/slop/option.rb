module Slop
  class Option
    attr_reader :flags, :desc, :config

    def initialize(flags, desc, config)
      @flags  = flags
      @desc   = desc
      @config = config
    end
  end
end
