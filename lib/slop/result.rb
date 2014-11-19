module Slop
  class Result
    attr_reader :parser, :options

    def initialize(parser)
      @parser  = parser
      @options = parser.options
    end

    def to_hash
      Hash[options.map { |o| [o.key, o.value] }]
    end
  end
end
