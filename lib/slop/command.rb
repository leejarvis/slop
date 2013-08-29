class Slop
  class Command
    DEFAULT_SHORT_PREFIX  = '-'
    DEFAULT_LONG_PREFIX   = '--'

    attr_reader :name, :config, :options, :commands

    def initialize(name, config = {}, &block)
      @name     = name
      @config   = Slop.config.merge(config)
      @options  = Options.new(self)
      @commands = Commands.new(self)
      @runner   = nil

      if block_given?
        block.arity == 1 ? yield(self) : instance_eval(&block)
      end
    end

    def option(*args, &block)
      options.add(args, &block)
    end

    alias_method :on, :option

    def command(name, config = {}, &block)
      commands.add(name, config, &block)
    end

    alias_method :cmd, :command

    # Returns the value for the option associated with this flag.
    def [](flag)
      options.find(flag).value
    end

    # Returns true if this option was present in parsed items.
    def present?(flag)
      options.find(flag).count > 0
    rescue OptionNotFound
      false
    end

    def parse!(items, config = {}, &block)
      Processor.process(self, items)
      @runner.call(self, items) if @runner.respond_to?(:call)
      self
    end

    def parse(items, config = {}, &block)
      parse!(items.dup, config, &block)
    end

    def process(runner = nil, &block)
      @runner = runner || block
    end

    # Returns true if this is the global/top level (Usually an instance of Slop).
    def global?
      name == :_global_
    end

    def strict?
      config[:strict]
    end

    def to_hash
      hash = options.to_hash
      if commands.any?
        hash.merge!(commands.to_hash)
      end
      hash
    end

    def short_flag_prefix
      config[:short_flag_prefix] || DEFAULT_SHORT_PREFIX
    end

    def long_flag_prefix
      config[:long_flag_prefix] || DEFAULT_LONG_PREFIX
    end

    # Returns true if this string matches a flag
    def flag_match?(flag)
      flag.start_with?(long_flag_prefix) || flag.start_with?(short_flag_prefix)
    end

    def clean_flag(flag)
      flag.to_s.sub(/\A#{long_flag_prefix}/, '').sub(/\A#{short_flag_prefix}/, '')
    end

    def respond_to_missing?(m, include_private = false)
      m[-1] == '?' && options.exists?(m[0..-2]) || super
    end

    def method_missing(m, *args, &block)
      m[-1] == '?' ? present?(m[0..-2]) : super
    end

  end
end
