module Slop
  class Parser
    attr_reader :options, :used_options

    def initialize(options)
      @options      = options
      @used_options = []
    end

    def parse(strings)
      pairs = strings.each_cons(2).to_a
      pairs << [strings.last, nil]

      pairs.each do |flag, arg|
        option = matching_option(flag)

        if option
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
