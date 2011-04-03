class Slop
  class Options < Array

    # @param [Boolean] symbols true to cast hash keys to symbols
    # @return [Hash]
    def to_hash(symbols)
      out = {}
      each do |option|
        key = option.key
        key = key.to_sym if symbols
        out[key] = option.argument_value
      end
      out
    end

    # @param [Object] flag The short/long flag representing the option
    # @return [Option] the option assoiated with this flag
    def [](flag)
      item = flag.to_s
      if item =~ /\A\d+\z/
        slice item.to_i
      else
        find do |option|
          option.short_flag == item || option.long_flag == item
        end
      end
    end

    # @see Slop#help
    # @return [String] All options in a pretty help string
    def to_help
      heads = reject {|x| x.tail }
      tails = select {|x| x.tail }
      (heads + tails).map(&:to_s).join("\n")
    end
  end
end