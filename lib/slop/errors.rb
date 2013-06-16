class Slop
  # The main Error class, all Exception classes inherit from this class.
  class Error < StandardError
  end

  # Raised when an option argument is expected but none are given.
  class MissingArgumentError < Error
  end

  # Raised when an option is expected/required but not present.
  class MissingOptionError < Error
  end

  # Raised when an argument does not match its intended match constraint.
  class InvalidArgumentError < Error
  end

  # Raised when an invalid option is found and the strict flag is enabled.
  class InvalidOptionError < Error
  end

  # Raised when an invalid command is found and the strict flag is enabled.
  class InvalidCommandError < Error
  end
end