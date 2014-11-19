module Slop
  class StringOption < Option
    def call(value)
      value.to_s
    end
  end

  class BoolOption < Option
    def call(_value)
      true
    end

    def expects_argument?
      false
    end
  end

  class IntegerOption < Option
    def call(value)
      value =~ /\A\d+\z/ && value.to_i
    end
  end

  class ArrayOption < Option
    def call(value)
      @value ||= []
      @value.concat value.split(delimiter)
    end

    def delimiter
      config[:delimiter] || ","
    end
  end
end
