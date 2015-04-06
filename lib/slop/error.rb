module Slop
  # Base error class.
  class Error < StandardError
  end

  # Raised when calling `call` on Slop::Option (this
  # method must be overriden in subclasses)
  class NotImplementedError < Error
  end

  # Raised when an option that expects an argument is
  # executed without one. Suppress with the `suppress_errors`
  # config option.
  class MissingArgument < Error
    def initialize(msg, argument)
      super(msg)
      @argument = argument
    end

    #Get all the flags that matches
    #the option with the missing argument
    def getFlags()
      return @argument
    end
  end

  # Raised when an unknown option is parsed. Suppress
  # with the `suppress_errors` config option.
  class UnknownOption   < Error;
    def initialize(msg, unknownOption)
      super(msg)
      @unknownOption = unknownOption
    end

    def getUnknowOption()
      return @unknownOption
    end
  end
end
