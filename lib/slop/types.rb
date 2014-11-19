module Slop
  class StringOption < Option
  end

  class BoolOption < Option
    def call(_value)
      @value = true
    end
  end
end
