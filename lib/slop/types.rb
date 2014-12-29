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

    def default_value
      config[:default] || false
    end

    def expects_argument?
      false
    end
  end
  BooleanOption = BoolOption

  class IntegerOption < Option
    def call(value)
      value =~ /\A\d+\z/ && value.to_i
    end
  end
  IntOption = IntegerOption

  class FloatOption < Option
    def call(value)
      # TODO: scientific notation, etc.
      value =~ /\A\d*\.*\d+\z/ && value.to_f
    end
  end

  class ArrayOption < Option
    def call(value)
      @value ||= []
      @value.concat value.split(delimiter)
    end

    def default_value
      config[:default] || []
    end

    def delimiter
      config[:delimiter] || ","
    end
  end

  # an option that discards the return value
  class NullOption < BoolOption
    def null?
      true
    end
  end

end
