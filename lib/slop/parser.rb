module Slop
  class Parser
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def parse(strings)
      pairs = strings.each_cons(2).to_a
      pairs << [strings.last, nil]

      pairs.each do |flag, arg|
        option = matching_option(flag)

        if option
          option.call(arg)
        end
      end

      Result.new(self)
    end

    private

    def matching_option(flag)
      options.find { |o| o.flags.include?(flag) }
    end
  end
end
