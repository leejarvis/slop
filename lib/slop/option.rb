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

    attr_reader :short, :long, :description, :config
    attr_accessor :count

    def initialize(slop, short, long, description, config = {}, &block)
      @short = short
      @long = long
      @description = description
      @config = DEFAULT_OPTIONS.merge(config)
      @count = 0
      @callback = block_given? ? block : config[:callback]
      @argument_value = nil

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
        case type.to_s.downcase
        when 'string', 'str' ; value.to_s
        when 'symbol', 'sym' ; value.to_s.to_sym
        when 'integer', 'int'; value.to_s.to_i
        when 'float'; value.to_s.to_f
        when 'array'; value.to_s.split(config[:delimiter], config[:limit])
        when 'range'; value_to_range(value)
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