class Slop
  class Commands

    attr_reader :config, :commands
    attr_writer :banner

    def initialize(config = {}, &block)
      @config = config
      @commands = {}
      @banner = nil

      if block_given?
        block.arity == 1 ? yield(self) : instance_eval(&block)
      end
    end

    def banner(banner = nil)
      @banner = banner if banner
      @banner
    end

    def on(command, config = {}, &block)
      config = @config.merge(config)
      commands[command] = Slop.new(config, &block)
    end

    def default(config = {}, &block)
      config = @config.merge(config)
      commands['default'] = Slop.new(config, &block)
    end

    def global(config = {}, &block)
      config = @config.merge(config)
      commands['global'] = Slop.new(config, &block)
    end

    def [](key)
      commands[key.to_s]
    end
    alias get []

    def parse(items = ARGV)
      parse_items(items)
    end

    def parse!(items = ARGV)
      parse_items(items, true)
    end

    def to_hash
      Hash[commands.map { |k, v| [k.to_sym, v.to_hash] }]
    end

    def to_s
      out = @banner ? "#{@banner}\n" : ""
      defaults = commands.delete('default')
      helps = commands.reject { |_, v| v.options.none? }
      helps.merge!('Other options' => defaults.to_s) if defaults
      helps.map { |key, opts| "  #{key}\n#{opts}" }.join("\n\n")
    end
    alias help to_s

    private

    def parse_items(items, bang = false)
      if opts = commands[items[0].to_s]
        items.shift
        bang ? opts.parse!(items) : opts.parse(items)
        execute_global_opts(items, bang)
      else
        if opts = commands['default']
          bang ? opts.parse!(items) : opts.parse(items)
        else
          if config[:strict] && items[0]
            raise InvalidCommandError, "Unknown command `#{items[0]}`"
          end
        end
        execute_global_opts(items, bang)
      end
      items
    end

    def execute_global_opts(items, bang)
      if global_opts = commands['global']
        bang ? global_opts.parse!(items) : global_opts.parse(items)
      end
    end

  end
end