class Slop
  class Options < Array

    # @param [Boolean] symbols true to cast hash keys to symbols
    # @return [Hash]
    def to_hash(symbols)
      reduce({}) do |hsh, option|
        key = option.key
        key = key.to_sym if symbols
        hsh[key] = option.argument_value
        hsh
      end
    end

    # Fetch an Option object
    #
    # @param [Object] flag The short/long flag representing the option
    # @example
    #   opts = Slop.parse { on :v, "Verbose mode" }
    #   opts.options[:v] #=> Option
    #   opts.options[:v].description #=> "Verbose mode"
    # @return [Option] the option assoiated with this flag
    def [](flag)
      if flag.is_a?(Integer)
        slice flag
      else
        item = flag.to_s
        find do |option|
          option.short_flag == item || option.long_flag == item
        end
      end
    end

    # @see Slop#help
    # @return [String] All options in a pretty help string
    def to_help
      heads = reject(&:tail)
      tails = select(&:tail)
      all = (heads + tails).select(&:help)
      all.map(&:to_s).join("\n")
    end
  end
end
