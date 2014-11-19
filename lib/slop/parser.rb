module Slop
  class Parser
    attr_reader :options, :used_options

    def initialize(options)
      @options = options

      reset
    end

    # Reset the parser, useful to use the same instance
    # to parse a second time without duplicating state.
    def reset
      @used_options = []

      self
    end

    def parse(strings)
      pairs = strings.each_cons(2).to_a
      pairs << [strings.last, nil]

      pairs.each do |flag, arg|
        break if flag == '--'

        if option = matching_option(flag)
          used_options << option

          option.call(arg)
        end
      end

      Result.new(self)
    end

    def unused_options
      options.to_a - used_options
    end

    private

    def matching_option(flag)
      options.find { |o| o.flags.include?(flag) }
    end
  end
end
