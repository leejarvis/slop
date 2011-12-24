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
      :as => String
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
      type = config[:as].to_s.downcase

      value = @argument_value || config[:default]
      return if value.nil?

      case type
      when 'string', 'str'
      when 'symbol', 'sym'
      when 'integer', 'int'
      when 'float'
      when 'array'
      when 'range'
      else
        value
      end
    end

    def inspect
      "#<Slop::Option [-#{short} | --#{long}" +
      "#{'=' if expects_argument?}#{'=?' if accepts_optional_argument?}]" +
      " (#{description}) #{config.inspect}"
    end

  end
end