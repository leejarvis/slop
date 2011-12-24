require 'slop/option'

class Slop
  VERSION = '3.0.0.rc1'

  class Error < StandardError; end
  class MissingArgumentError < Error; end
  class MissingOptionError < Error; end
  class InvalidArgumentError < Error; end
  class InvalidOptionError < Error; end

  DEFAULT_OPTIONS = {
    :strict => false,
    :help => false,
    :banner => nil,
    :ignore_case => false,
    :autocreate => false,
    :arguments => false,
    :optional_arguments => false
  }

  class << self
    def parse(items = ARGV, config = {}, &block)
      init_and_parse(items, false, config, &block)
    end

    def parse!(items = ARGV, config = {}, &block)
      init_and_parse(items, true, config, &block)
    end

    def optspec(string, config = {})
      # Slop.new(config)
    end

    private

    def init_and_parse(items, delete, config, &block)
      config, items = items, ARGV if items.is_a?(Hash) && config.empty?
      slop = Slop.new(config, &block)
      delete ? slop.parse!(items) : slop.parse(items)
      slop
    end
  end

  attr_reader :config, :options

  def initialize(config = {}, &block)
    @config = DEFAULT_OPTIONS.merge(config)
    @options = []
    @trash = []
    @callbacks = Hash.new([])

    if config[:help]
      on('-h', '--help', 'Display this help message.', :tail => true) do
        $stderr.puts help
      end
    end
  end

  def parse(items = ARGV, &block)
    parse_items(items, false, &block)
  end

  def parse!(items = ARGV, &block)
    parse_items(items, true, &block)
  end

  def on(*objects, &block)
    short, long, description, conf = build_option(objects)
    option = Option.new(self, short, long, description, conf, &block)
    options << option
    option
  end
  alias option on
  alias opt on

  def [](key)
    option = fetch_option(key)
    option.value if option
  end
  alias get []

  def to_hash
    Hash[options.map { |opt| [opt.key.to_sym, opt.value] }]
  end

  def present?(*option_keys)
    option_keys.all? { |key| option = fetch_option(key) && option.count > 0 }
  end

  def fetch_option(key)
    options.find { |option| [option.long, option.short].include?(clean(key)) }
  end

  def add_callback(label, &block)
    @callbacks[label] << block
  end

  private

  def parse_items(items, delete, &block)
    items = Array(items)
    if items.empty? && @callbacks[:empty].any?
      @callbacks[:empty].each { |cb| cb.call(self) }
      return items
    end

    items.each_with_index do |item, index|
      @trash << index && break if item == '--'
      process_item(item, index, &block) unless @trash.include?(index)
    end

    required_options = options.select { |opt| opt.required? && opt.count < 1 }
    if required_options.any?
      raise MissingOptionError,
        "Missing required option(s): #{required_options.map(&:key).join(', ')}"
    end

    items
  end

  def process_item(item, index, &block)
    option, argument = extract_option(item) if item[0, 1] == '-'
    if option
      option.count += 1 unless item[0, 5] == '--no-'

      if option.expects_argument?
        argument ||= items.at(index + 1)
        @trash << index + 1
      elsif option.accepts_optional_argument?

      end
    else
      block.call(item) if block && !@trash.include?(index)
    end
  end

  def extract_option(flag)
    option = fetch_option(flag)
    option ||= fetch_option(flag.downcase) if config[:ignore_case]

    unless option
      case flag
      when /\A--?([^=]+)=(.+)\z/
        option, argument = fetch_option($1), $2
      when /\A--no-(.+)\z/
        option, argument = fetch_option($1), false
      end
    end

    [option, argument]
  end

  def build_option(objects)
    items = []
    config = {}
    config[:argument] = true if @config[:arguments]
    config[:optional_argument] = true if @config[:optional_arguments]

    items.push(extract_short_flag(objects, config)) # short flag
    items.push(extract_long_flag(objects, config))  # long flag
    items.push(objects[0].respond_to?(:to_str) ? objects.shift : nil) # description
    config.merge!(objects.last) if objects.last.is_a?(Hash)
    items.push(config) # config options
  end

  def extract_short_flag(objects, config)
    flag = clean(objects.first)

    if flag.size == 2 && flag[-1, 1] == '='
      config[:argument] = true
      flag.chop!
    end

    if flag.size == 1
      objects.shift
      flag
    end
  end

  def extract_long_flag(objects, config)
    flag = objects.first.to_s
    if flag =~ /\A(?:--?)?[a-zA-Z][a-zA-Z0-9_-]+\=?\z/
      config[:argument] = true if flag[-1, 1] == '='
      objects.shift
      clean(flag).sub(/\=\z/, '')
    end
  end

  def clean(object)
    object.to_s.sub(/\A--?/, '')
  end

end