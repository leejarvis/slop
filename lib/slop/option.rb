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
      # ...
    end

    def value
      # ...
    end

  end
end