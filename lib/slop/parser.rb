module Slop
  class Parser

    # Our Options instance.
    attr_reader :options

    # A Hash of configuration options.
    attr_reader :config

    # Returns an Array of String arguments that were not parsed.
    attr_reader :arguments

    def initialize(options, **config)
      @options = options
      @config  = config
      reset
    end

    # Reset the parser, useful to use the same instance to parse a second
    # time without duplicating state.
    def reset
      @arguments = []
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
      reset # reset before every parse

      pairs = strings.each_cons(2).to_a
      # this ensures we still support the last string being a flag,
      # otherwise it'll only be used as an argument.
      pairs << [strings.last, nil]

      @arguments = strings.dup

      pairs.each_with_index do |pair, idx|
        flag, arg = pair
        break if !flag

        # ignore everything after '--', flag or not
        if flag == '--'
          arguments.delete(flag)
          break
        end

        # support `foo=bar`
        orig_flag = flag.dup
        orig_arg = arg
        if flag.include?("=")
          flag, arg = flag.split("=")
        end

        if opt = try_process(flag, arg)
          # since the option was parsed, we remove it from our
          # arguments (plus the arg if necessary)
          # delete argument first while we can find its index.
          if opt.expects_argument?

            # if we consumed the argument, remove the next pair
            if orig_arg == opt.value.to_s
              pairs.delete_at(idx + 1)
            end

            arguments.each_with_index do |argument, i|
              if argument == orig_flag && !orig_flag.include?("=")
                arguments.delete_at(i + 1)
              end
            end
          end
          arguments.delete(orig_flag)
        end
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

    # We've found an option, process and return it
    def process(option, arg)
      option.ensure_call(arg)
      option
    end

    # Try and find an option to process
    def try_process(flag, arg)
      if option = matching_option(flag)
        process(option, arg)
      elsif flag.start_with?("--no-") && option = matching_option(flag.sub("no-", ""))
        process(option, false)
      elsif flag =~ /\A-[^-]{2,}/
        # try and process as a set of grouped short flags. drop(1) removes
        # the prefixed -, then we add them back to each flag separately.
        flags = flag.split("").drop(1).map { |f| "-#{f}" }
        last  = flags.pop

        flags.each { |f| try_process(f, nil) }
        try_process(last, arg) # send the argument to the last flag
      else
        if flag.start_with?("-") && !suppress_errors?
          raise UnknownOption.new("unknown option `#{flag}'", "#{flag}")
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
