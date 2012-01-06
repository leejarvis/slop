class Slop
  class Option

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

    DEFAULT_TYPES = {
      :string  => proc { |v| v.to_s },
      :symbol  => proc { |v| v.to_sym },
      :integer => proc { |v| v.to_s.to_i },
      :float   => proc { |v| v.to_f }
    }

    attr_reader :short, :long, :description, :config, :types
    attr_accessor :count

    def initialize(slop, short, long, description, config = {}, &block)
      @short = short
      @long = long
      @description = description
      @config = DEFAULT_OPTIONS.merge(config)
      @count = 0
      @callback = block_given? ? block : config[:callback]
      @argument_value = nil

      @types = DEFAULT_TYPES.merge(
        :array => proc { |v| v.split(@config[:delimiter], @config[:limit]) },
        :range => proc { |v| value_to_range(v) }
      )

      @config.each_key do |key|
        self.class.send(:define_method, "#{key}?") { !!@config[key] }
      end
    end

    def expects_argument?
      config[:argument] && config[:argument] != :optional
    end

    def accepts_optional_argument?
      config[:optional_argument] || config[:argument] == :optional
    end

    def key
      @long || @short
    end

    def call(*objects)
      @callback.call(*objects) if @callback.respond_to?(:call)
    end

    def value=(value)
      @argument_value = value
    end

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

    def inspect
      "#<Slop::Option [-#{short} | --#{long}" +
      "#{'=' if expects_argument?}#{'=?' if accepts_optional_argument?}]" +
      " (#{description}) #{config.inspect}"
    end

    private

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