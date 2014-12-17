module Slop
  class Parser
    attr_reader :options, :config

    def initialize(options, **config)
      @options = options
      @config  = config

      reset
    end

    # Reset the parser, useful to use the same instance to parse a second
    # time without duplicating state.
    def reset
      @options.each(&:reset)
      self
    end

    # Traverse `strings` and process options one by one. Anything after
    # `--` is ignored. If a flag includes a equals (=) it will be split
    # so that `flag, argument = s.split('=')`.
    #
    # The `call` method will be executed immediately for each option found.
    # Once all options have been executed, any found options will have
    # the `finish` method called on them.
    #
    # Returns a Slop::Result.
    def parse(strings)
      pairs = strings.each_cons(2).to_a
      pairs << [strings.last, nil]

      pairs.each do |flag, arg|
        break if !flag || flag == '--'

        if flag.include?("=")
          flag, arg = flag.split("=")
        end

        try_process(flag, arg)
      end

      Result.new(self).tap do |result|
        used_options.each { |o| o.finish(result) }
      end
    end

    # Returns an Array of Option instances that were used.
    def used_options
      options.select { |o| o.count > 0 }
    end

    # Returns an Array of Option instances that were not used.
    def unused_options
      options.to_a - used_options
    end

    private

    # We've found an option, process it
    def process(option, arg)
      option.ensure_call(arg)
    end

    # Try and find an option to process
    def try_process(flag, arg)
      if option = matching_option(flag)
        process(option, arg)
      elsif flag =~ /\A-[^-]/ && flag.size > 2
        # try and process as a set of grouped short flags
        flags = flag.split("").drop(1).map { |f| "-#{f}" }
        last  = flags.pop

        flags.each { |f| try_process(f, nil) }
        try_process(last, arg) # send the argument to the last flag
      else
        if flag.start_with?("-") && !suppress_errors?
          raise UnknownOption, "unknown option `#{flag}'"
        end
      end
    end

    def suppress_errors?
      config[:suppress_errors]
    end

    def matching_option(flag)
      options.find { |o| o.flags.include?(flag) }
    end
  end
end
