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

    # items  - The Array of items to extract options from (default: ARGV).
    # config - The Hash of configuration options to send to Slop.new().
    # block  - An optional block used to add options.
    #
    # Examples:
    #
    #   Slop.parse(ARGV, :help => true) do
    #     on '-n', '--name', 'Your username', :argument => true
    #   end
    #
    # Returns a new instance of Slop.
    def parse(items = ARGV, config = {}, &block)
      init_and_parse(items, false, config, &block)
    end

    # items  - The Array of items to extract options from (default: ARGV).
    # config - The Hash of configuration options to send to Slop.new().
    # block  - An optional block used to add options.
    #
    # Returns a new instance of Slop.
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
    @callbacks = {}

    if block_given?
      block.arity == 1 ? yield(self) : instance_eval(&block)
    end

    if config[:help]
      on('-h', '--help', 'Display this help message.', :tail => true) do
        $stderr.puts help
      end
    end
  end

  # Parse a list of items, executing and gathering options along the way.
  #
  # items - The Array of items to extract options from (default: ARGV).
  # block - An optional block which when used will yield non options.
  #
  # Returns an Array of original items.
  def parse(items = ARGV, &block)
    parse_items(items, false, &block)
  end

  # Parse a list of items, executing and gathering options along the way.
  # unlike parse() this method will remove any options and option arguments
  # from the original Array.
  #
  # items - The Array of items to extract options from (default: ARGV).
  # block - An optional block which when used will yield non options.
  #
  # Returns an Array of original items with options removed.
  def parse!(items = ARGV, &block)
    parse_items(items, true, &block)
  end

  # Add an Option.
  #
  # objects - An Array with an optional Hash as the last element.
  #
  # Examples:
  #
  #   on '-u', '--username=', 'Your username'
  #   on :v, :verbose, 'Enable verbose mode'
  #
  # Returns the created instance of Slop::Option.
  def on(*objects, &block)
    option = build_option(objects, &block)
    options << option
    option
  end
  alias option on
  alias opt on

  # Fetch an options argument value.
  #
  # key - The Symbol or String option short or long flag.
  #
  # Returns the Object value for this option, or nil.
  def [](key)
    option = fetch_option(key)
    option.value if option
  end
  alias get []

  # Returns a new Hash with option flags as keys and option values as values.
  def to_hash
    Hash[options.map { |opt| [opt.key.to_sym, opt.value] }]
  end

  # Check for an options presence.
  #
  # Examples:
  #
  #   opts.parse %w( --foo )
  #   opts.present?(:foo) #=> true
  #   opts.present?(:bar) #=> false
  #
  # Returns true if all of the keys are present in the parsed arguments.
  def present?(*option_keys)
    option_keys.all? { |key| option = fetch_option(key) && option.count > 0 }
  end

  # Fetch a Slop::Option object.
  #
  # key - The Symbol or String option key.
  #
  # Examples:
  #
  #   opts.on(:foo, 'Something fooey', :argument => :optional)
  #   opt = opts.fetch_option(:foo)
  #   opt.class #=> Slop::Option
  #   opt.accepts_optional_argument? #=> true
  #
  # Returns an Option or nil if none were found.
  def fetch_option(key)
    options.find { |option| [option.long, option.short].include?(clean(key)) }
  end

  # Add a callback.
  #
  # label - The Symbol identifier to attach this callback.
  #
  # Returns nothing.
  def add_callback(label, &block)
    (@callbacks[label] ||= []) << block
  end

  private

  def parse_items(items, delete, &block)
    if items.empty? && @callbacks[:empty]
      @callbacks[:empty].each { |cb| cb.call(self) }
      return items
    end

    items.each_with_index do |item, index|
      @trash << index && break if item == '--'
      process_item(items, index, &block) unless @trash.include?(index)
    end

    required_options = options.select { |opt| opt.required? && opt.count < 1 }
    if required_options.any?
      raise MissingOptionError,
        "Missing required option(s): #{required_options.map(&:key).join(', ')}"
    end

    items.reject!.with_index { |item, index| @trash.include?(index) } if delete
    items
  end

  def process_item(items, index, &block)
    item = items[index]
    option, argument = extract_option(item) if item[0, 1] == '-'

    if option
      option.count += 1 unless item[0, 5] == '--no-'
      @trash << index

      if option.expects_argument?
        argument ||= items.at(index + 1)

        if !argument || argument =~ /\A--?[a-zA-Z][a-zA-Z0-9_-]*\z/
          raise MissingArgumentError, "#{option.key} expects an argument"
        end

        execute_option(option, argument, index)
      elsif option.accepts_optional_argument?
        argument ||= items.at(index + 1)

        if argument && argument !~ /\A--?/
          execute_option(option, argument, index)
        else
          option.call(nil)
        end
      end
    else
      block.call(item) if block && !@trash.include?(index)
    end
  end

  def execute_option(option, argument, index)
    @trash << index + 1
    option.value = argument

    if option.match? && !argument.match(option.config[:match])
      raise InvalidArgumentError, "#{argument} is an invalid argument"
    end

    option.call(option.value)
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

  def build_option(objects, &block)
    config = {}
    config[:argument] = true if @config[:arguments]
    config[:optional_argument] = true if @config[:optional_arguments]

    short  = extract_short_flag(objects, config)
    long   = extract_long_flag(objects, config)
    desc   = objects[0].respond_to?(:to_str) ? objects.shift : nil
    config = config.merge!(objects.last) if objects.last.is_a?(Hash)

    Option.new(self, short, long, desc, config, &block)
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