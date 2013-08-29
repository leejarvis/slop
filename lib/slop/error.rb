class Slop

  class Error < StandardError
    attr_reader :command

    def initialize(command, message = nil)
      super message
      @command = command
    end

    def opts
      @command
    end

    def help
      @command.help
    end
  end

  # Raised when an option was included in the parse list, but not defined.
  class OptionNotFound < Error
  end

  # Raised when an option expects an argument but none was given.
  class MissingArgument < Error
  end

  # others

end
