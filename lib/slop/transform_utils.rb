module Slop
  module TransformUtils

    def symbol_friendly(string)
      # Ugly but due to the fact Result has no direct access to config
      if respond_to? :config
        return string unless config[:friendly_symbols]
      end
      if respond_to? :parser
        return string unless parser.config[:friendly_symbols]
      end
      string.tr '-', '_'
    end

  end
end