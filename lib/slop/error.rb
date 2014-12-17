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
  end

  # Raised when an unknown option is parsed. Suppress
  # with the `suppress_errors` config option.
  class UnknownOption   < Error; end
end
