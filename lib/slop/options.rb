class Slop
  class Options
    include Enumerable

    attr_reader :command, :collection

    # command - The Slop::Command this collection belongs to.
    def initialize(command)
      @command    = command
      @collection = []
    end

    def add(args, &block)
      collection << Option.build(command, args, &block)
    end

    # Find an option via its flag.
    #
    # Raises OptionNotFound if no option was found.
    # Returns a Slop::Option.
    def find(flag)
      flag = command.clean_flag(flag)
      each do |option|
        return option if option.long == flag || option.short == flag
      end
      raise OptionNotFound.new(command, "No such option -- `#{flag}'")
    end

    # Like find, but returns nil if no option is found
    def [](flag)
      find(command.clean_flag(flag))
    rescue OptionNotFound
      nil
    end

    def each(&block)
      collection.each(&block)
    end

    # Returns true if an option with this flag exists, false otherwise.
    def exists?(flag)
      find(command.clean_flag(flag))
      true
    rescue OptionNotFound
      false
    end

    def to_hash
      each_with_object({}) { |o, h| h[o.key.to_sym] = o.value }
    end

  end
end
