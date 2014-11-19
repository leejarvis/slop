module Slop
  class Error < StandardError
  end

  class MissingArgument < Error; end
  class UnknownOption   < Error; end
end
