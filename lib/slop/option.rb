class Slop
  class Option

    # The default Hash of configuration options this class uses.
    DEFAULT_OPTIONS = {
      :argument => false,
      :optional_argument => false,
      :tail => false,
      :default => nil,
      :callback => nil,
      :delimiter => ',',
      :limit => 0,
      :match => nil,
      :optional => true,
      :required => false,
      :as => String,
      :autocreated => false
    }

    attr_reader :short, :long, :description, :config, :types
    attr_accessor :count

    # Incapsulate internal option information, mainly used to store
    # option specific configuration data, most of the meat of this
    # class is found in the #value method.
    #
    # slop        - The instance of Slop tied to this Option.
    # short       - The String or Symbol short flag.
    # long        - The String or Symbol long flag.
    # description - The String description text.
    # config      - A Hash of configuration options.
    # block       - An optional block used as a callback.
    def initialize(slop, short, long, description, config = {}, &block)
      @short = short
      @long = long
      @description = description
      @config = DEFAULT_OPTIONS.merge(config)
      @count = 0
      @callback = block_given? ? block : config[:callback]
      @argument_value = nil

      @types = {
        :string  => proc { |v| v.to_s },
        :symbol  => proc { |v| v.to_sym },
        :integer => proc { |v| v.to_s.to_i },
        :float   => proc { |v| v.to_f },
        :array   => proc { |v| v.split(@config[:delimiter], @config[:limit]) },
        :range   => proc { |v| value_to_range(v) }
      }

      @config.each_key do |key|
        self.class.send(:define_method, "#{key}?") { !!@config[key] }
      end
    end

    # Returns true if this option expects an argument.
    def expects_argument?
      config[:argument] && config[:argument] != :optional
    end

    # Returns true if this option accepts an optional argument.
    def accepts_optional_argument?
      config[:optional_argument] || config[:argument] == :optional
    end

    # Returns the String flag of this option. Preferring the long flag.
    def key
      @long || @short
    end

    # Call this options callback if one exists, and it responds to call().
    #
    # Returns nothing.
    def call(*objects)
      @callback.call(*objects) if @callback.respond_to?(:call)
    end

    # Set the argument value for this option.
    #
    # value - The Object to set the argument value.
    #
    # Returns nothing.
    def value=(value)
      @argument_value = value
    end

    # Fetch the argument value for this option.
    #
    # Returns the Object once any type conversions have taken place.
    def value
      value = @argument_value || config[:default]
      return if value.nil?

      type = config[:as]
      if type.respond_to?(:call)
        type.call(value)
      else
        type = type.to_s.downcase.to_sym
        if types.key?(type)
          types[type].call(value)
        else
          value
        end
      end
    end

    # Returns the String inspection text.
    def inspect
      "#<Slop::Option [-#{short} | --#{long}" +
      "#{'=' if expects_argument?}#{'=?' if accepts_optional_argument?}]" +
      " (#{description}) #{config.inspect}"
    end

    private

    # Convert an object to a Range if possible. If this method is passed
    # what does *not* look like a Range, but looks like an Integer of some
    # sort, it will call #to_i on the Object and return the Integer
    # representation.
    #
    # value - The Object we want to convert to a range.
    #
    # Returns the Range value if one could be found, else the original object.
    def value_to_range(value)
      case value.to_s
      when /\A(-?\d+?)(\.\.\.?|-|,)(-?\d+)\z/
        Range.new($1.to_i, $3.to_i, $2 == '...')
      when /\A-?\d+\z/
        value.to_i
      else
        value
      end
    end

  end
end