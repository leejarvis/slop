class Slop
  class Commands

    attr_reader :commands

    def initialize(config = {}, &block)
      @default_slop_config = config
      @commands = {}

      if block_given?
        block.arity == 1 ? yield(self) : instance_eval(&block)
      end
    end

    def on(command, config = {}, &block)
      config = @default_slop_config.merge(config)
      commands[command] = Slop.new(config, &block)
    end

    def [](key)
      commands[key.to_s]
    end

    def to_s
      commands.map { |key, opts|
        " #{key}\n#{opts}"
      }.join("\n\n")
    end
    alias help to_s

  end
end