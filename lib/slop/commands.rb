class Slop
  class Commands
    include Enumerable

    attr_reader :command, :collection

    def initialize(command)
      @command    = command
      @collection = {}
    end

    def add(name, config, &block)
      collection[name.to_s] = Command.new(name.to_s, config, &block)
    end

    # Returns the Slop::Command for this command, nil if one does not exist.
    def [](command)
      collection[command.to_s]
    end

    def each(&block)
      collection.each(&block)
    end

    def to_hash
      hash = {}
      each { |name, command| hash[name.to_sym] = command.to_hash }
      hash
    end

  end
end
