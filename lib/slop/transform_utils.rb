module Slop
  module TransformUtils

    def symbol_friendly(astring)
      astring.tr '-', '_'
    end
    
  end
end