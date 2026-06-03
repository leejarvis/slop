# frozen-string-literal: true

module Slop
  class Parser
    # Our Options instance.
    attr_reader :options

    # A Hash of configuration options.
    attr_reader :config

    # Returns an Array of String arguments that were not parsed.
    attr_reader :arguments

    # Per-parser option value storage. Prevents cross-Parser contamination
    # when two Parser instances share the same Options (see #228).
    attr_reader :opt_values

    def initialize(options, **config)
      @options = options
      @config  = config
      @opt_values = {}
      reset
    end

    # Reset the parser, useful to use the same instance to parse a second
    # time without duplicating state.
    def reset
      @arguments = []
      @opt_values = {}
      @options.each(&:reset)
      self
    end

    # Traverse `strings` and process options one by one. Anything after
    # `--` is ignored. If a flag includes an equals sign (=) or colon (:)
    # it will be split so that `flag, argument = s.split(/[=:]/)`.
    #
    # The `call` method will be executed immediately for each option found.
    # Once all options have been executed, any found options will have
    # the `finish` method called on them.
    #
    # Returns a Slop::Result.
    def parse(strings)
      reset

      strings, ignored_args = partition(strings)

      pairs = strings.each_cons(2).to_a
      pairs << [strings.last, nil]

      @arguments = strings.dup

      pairs.each_with_index do |pair, idx|
        flag, arg = pair
        break if !flag

        orig_flag = flag.dup
        if match = flag.match(/([^=:]+)[=:](.*)/)
          flag, arg = match.captures
        end

        if opt = try_process(flag, arg)
          if opt.expects_argument?
            if consume_next_argument?(orig_flag)
              pairs.delete_at(idx + 1)
            end

            arguments.each_with_index do |argument, i|
              if argument == orig_flag && !orig_flag.include?("=") && !orig_flag.include?(":")
                arguments.delete_at(i + 1)
              end
            end
          end
          arguments.delete(orig_flag)
        end
      end

      @arguments += ignored_args

      if !suppress_errors?
        unused_options.each do |o|
          if o.config[:required]
            pretty_flags = o.flags.map { |f| "`#{f}'" }.join(", ")
            raise MissingRequiredOption, "missing required option #{pretty_flags}"
          end
        end
      end

      result = Result.new(self)
      used_options.each { |o| o.finish(result) }
      @options.each { |o| @opt_values[o] = o.value unless o.null? }
      result
    end

    # Returns an Array of Option instances that were used.
    def used_options = options.select { _1.count > 0 }

    # Returns an Array of Option instances that were not used.
    def unused_options = options.to_a - used_options

    private

    def consume_next_argument?(flag)
      return false if flag.include?("=") || flag.include?(":")
      return true if flag.start_with?("--")
      /\A-[a-zA-Z]\z/.match?(flag)
    end

    def process(option, arg)
      option.ensure_call(arg)
      option
    end

    def try_process(flag, arg)
      if option = matching_option(flag)
        process(option, arg)
      elsif flag.start_with?("--no-") && option = matching_option(flag.sub("no-", ""))
        process(option, false)
      elsif flag.match?(/\A-[^-]{2,}/)
        try_process_smashed_arg(flag) || try_process_grouped_flags(flag, arg)
      else
        if flag.start_with?("-") && !suppress_errors?
          raise UnknownOption.new("unknown option `#{flag}'", "#{flag}")
        end
      end
    end

    # Try and process a flag with a "smashed" argument, e.g.
    # -nFoo or -i5
    def try_process_smashed_arg(flag)
      option = matching_option(flag[0, 2])
      process(option, flag[2..]) if option&.expects_argument?
    end

    # Try and process as a set of grouped short flags. drop(1) removes
    # the prefixed -, then we add them back to each flag separately.
    def try_process_grouped_flags(flag, arg)
      flags = flag.split("").drop(1).map { |f| "-#{f}" }
      last  = flags.pop

      flags.each { |f| try_process(f, nil) }
      try_process(last, arg)
    end

    def suppress_errors? = config[:suppress_errors]

    def matching_option(flag) = options.find { _1.flags.include?(flag) }

    def partition(strings)
      case idx = strings.index("--")
      in nil then [strings, []]
      in 0   then [[], strings[1..]]
      else [strings[0..idx-1], strings[idx+1..]]
      end
    end
  end
end
