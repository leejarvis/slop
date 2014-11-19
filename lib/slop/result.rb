module Slop
  class Result
    attr_reader :parser

    def initialize(parser)
      @parser  = parser
      @options = parser.options
    end
  end
end
