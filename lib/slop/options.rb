class Slop
  class Options < Array

    # Fetch an Option object. This method overrides Array#[] to provide
    # a nicer interface for fetching options via their short or long flag.
    # The reason we don't use a Hash here is because an option cannot be
    # identified by a single label. Instead this method tests against
    # a short flag first, followed by a long flag. When passing this
    # method an Integer, it will work as an Array usually would, fetching
    # the Slop::Option at this index.
    #
    # @param [Object] flag The short/long flag representing the option
    # @example
    #   opts = Slop.parse { on :v, "Verbose mode" }
    #   opts.options[:v] #=> Option
    #   opts.options[:v].description #=> "Verbose mode"
    # @return [Option] the option assoiated with this flag
    def [](flag)
      if flag.is_a? Integer
        super
      else
        find do |option|
          [option.short_flag, option.long_flag].include? flag.to_s
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
