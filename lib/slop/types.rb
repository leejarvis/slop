module Slop
  # Cast the option argument to a String.
  class StringOption < Option
    def call(value)
      value.to_s
    end
  end

  # Cast the option argument to true or false.
  # Override default_value to default to false instead of nil.
  # This option type does not expect an argument. However, the API
  # supports value being passed. This is to ensure it can capture
  # an explicit false value
  class BoolOption < Option
    attr_accessor :explicit_value

    def call(value)
      self.explicit_value = value
      !force_false?
    end

    def value
      if force_false?
        false
      else
        super
      end
    end

    def force_false?
      explicit_value == false
    end

    def default_value
      config[:default] || false
    end

    def expects_argument?
      false
    end
  end
  BooleanOption = BoolOption

  # Cast the option argument to an Integer.
  class IntegerOption < Option
    def call(value)
      value =~ /\A-?\d+\z/ && value.to_i
    end
  end
  IntOption = IntegerOption

  # Cast the option argument to a Float.
  class FloatOption < Option
    def call(value)
      # TODO: scientific notation, etc.
      value =~ /\A-?\d*\.*\d+\z/ && value.to_f
    end
  end

  # Collect multiple items into a single Array. Support
  # arguments separated by commas or multiple occurences.
  class ArrayOption < Option
    def call(value)
      @value ||= []
      if delimiter
        @value.concat value.split(delimiter, limit)
      else
        @value << value
      end
    end

    def default_value
      config[:default] || []
    end

    def delimiter
      config.fetch(:delimiter, ",")
    end

    def limit
      config[:limit] || 0
    end
  end

  # Cast the option argument to a Regexp.
  class RegexpOption < Option
    def call(value)
      Regexp.new(value)
    end
  end

  # An option that discards the return value, inherits from Bool
  # since it does not expect an argument.
  class NullOption < BoolOption
    def null?
      true
    end
  end
end
