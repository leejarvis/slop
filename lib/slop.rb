require 'slop/options'
require 'slop/option'

class Slop
  include Enumerable

  # Raised when an option expects an argument and none is given
  class MissingArgumentError < RuntimeError; end

  # Raised when an option specifies the `:match` attribute and this
  # options argument does not match this regexp
  class InvalidArgumentError < RuntimeError; end

  # Raised when the `:strict` option is enabled and an unknown
  # or unspecified option is used
  class InvalidOptionError < RuntimeError; end

  # @return [String] The current version string
  VERSION = '1.4.0'

  # Parses the items from a CLI format into a friendly object.
  #
  # @param [Array] items Items to parse into options.
  # @example Specifying three options to parse:
  #  opts = Slops.parse do
  #    on :v, :verbose, 'Enable verbose mode'
  #    on :n, :name,    'Your name'
  #    on :a, :age,     'Your age'
  #  end
  #  -------
  #  program.rb --verbose -n 'Emily' -a 25
  # @return [Slop] Returns an instance of Slop.
  def self.parse(items=ARGV, options={}, &block)
    initialize_and_parse(items, false, options, &block)
  end

  # Identical to {Slop.parse}, but removes parsed options from the original Array.
  #
  # @return [Slop] Returns an instance of Slop.
  def self.parse!(items=ARGV, options={}, &block)
    initialize_and_parse(items, true, options, &block)
  end

  # @return [Options]
  attr_reader :options

  attr_writer :banner
  attr_accessor :longest_flag

  # @param [Hash] options
  # @option opts [Boolean] :help Automatically add the `help` option
  # @option opts [Boolean] :strict Strict mode raises when a non listed
  #   option is found, false by default
  # @option opts [Boolean] :multiple_switches Allows `-abc` to be processed
  #   as the options 'a', 'b', 'c' and will force their argument values to
  #   true. By default Slop with parse this as 'a' with the argument 'bc'
  def initialize(*opts, &block)
    sloptions = {}
    sloptions.merge! opts.pop if opts.last.is_a? Hash
    opts.each { |o| sloptions[o] = true }

    @options = Options.new
    @banner = nil
    @longest_flag = 0
    @strict = sloptions[:strict]
    @invalid_options = []
    @multiple_switches = sloptions[:multiple_switches]

    if block_given?
      block.arity == 1 ? yield(self) : instance_eval(&block)
    end

    if sloptions[:help]
      on :h, :help, 'Print this help message', :tail => true do
        puts help
        exit
      end
    end
  end

  # Set or return banner text.
  #
  # @param [String] text Displayed banner text.
  # @example
  #   opts = Slop.parse do
  #     banner "Usage - ruby foo.rb [arguments]"
  #   end
  # @return [String] Returns current banner.
  def banner(text=nil)
    @banner = text if text
    @banner
  end

  # Parse a list of options, leaving the original Array unchanged.
  #
  # @param items
  def parse(items=ARGV, &block)
    parse_items items, &block
  end

  # Parse a list of options, removing parsed options from the original Array.
  #
  # @param items
  def parse!(items=ARGV, &block)
    parse_items items, true, &block
  end

  # Enumerable interface
  def each
    return enum_for(:each) unless block_given?
    @options.each { |option| yield option }
  end

  # Return the value of an option via the subscript operator.
  #
  # @param [Symbol] key Option symbol.
  # @example
  #   opts[:name] #=> "Emily"
  # @return [Object] Returns the value associated with that option.
  def [](key)
    option = @options[key]
    option.argument_value if option
  end

  # Specify an option with a short or long version, description and type.
  #
  # @param [*] args Option configuration.
  # @option args [Symbol, String] :short_flag Short option name.
  # @option args [Symbol, String] :long_flag Full option name.
  # @option args [String] :description Option description for use in Slop#help
  # @option args [Boolean] :argument Specifies whether a required option or not.
  # @option args [Hash] :options Optional option configurations.
  # @example
  #   opts = Slop.parse do
  #     on :n, :name, 'Your username', true # Required argument
  #     on :a, :age,  'Your age (optional)', :optional => true
  #     on :g, :gender, 'Your gender', :optional => false
  #     on :V, :verbose, 'Run in verbose mode', :default => true
  #     on :P, :people, 'Your friends', true, :as => Array
  #     on :h, :help, 'Print this help screen' do
  #       puts help
  #     end
  #   end
  # @return [Slop::Option]
  def option(*args, &block)
    options = args.pop if args.last.is_a?(Hash)
    options ||= {}

    short, long, desc, arg = clean_options(args)
    option = Option.new(self, short, long, desc, arg, options, &block)
    @options << option

    option
  end
  alias :opt :option
  alias :on :option

  # Returns the parsed list into a option/value hash.
  #
  # @example
  #   opts.to_hash #=> { 'name' => 'Emily' }
  #
  #   # symbols!
  #   opts.to_hash(true) #=> { :name => 'Emily' }
  # @return [Hash]
  def to_hash(symbols=nil)
    @options.to_hash(symbols)
  end
  alias :to_h :to_hash

  # Allows you to check whether an option was specified in the parsed list.
  #
  # @example
  #   #== ruby foo.rb -v
  #   opts.verbose? #=> true
  #   opts.name?    #=> false
  # @return [Boolean] Whether the desired option was specified.
  def method_missing(meth, *args, &block)
    super unless meth.to_s =~ /\?\z/
    !!self[meth.to_s.chomp '?']
  end

  # Returns the banner followed by available options listed on the next line.
  #
  # @example
  #  opts = Slop.parse do
  #    banner "Usage - ruby foo.rb [arguments]"
  #    on :v, :verbose, "Enable verbose mode"
  #  end
  #  puts opts
  # @return [String] Help text.
  def to_s
    banner = "#{@banner}\n" if @banner
    (banner || '') + options.to_help
  end
  alias :help :to_s

private

  def self.initialize_and_parse(items, delete, options, &block)
    if items.is_a?(Hash) && options.empty?
      options = items
      items = ARGV
    end

    slop = new(options, &block)
    delete ? slop.parse!(items) : slop.parse(items)
    slop
  end

  def parse_items(items, delete=false, &block)
    trash = []

    items.each do |item|
      item = item.to_s
      flag = item.sub(/^--?/, '')
      option = @options[flag]

      unless option
        case item
        when /\A-[^-]/
          if @multiple_switches
            enable_multiple_switches(item)
            next
          else
            flag, argument = flag.split('', 2)
            option = @options[flag]
          end
        when /\A--([^=]+)=(.+)\z/
          option = @options[$1]
          argument = $2
        when /\A--no-(.+)\z/
          option.force_argument_value(false) if option = @options[$1]
        end
      end

      if option
        trash << item
        next if option.forced?
        option.argument_value = true

        if option.expects_argument? || option.accepts_optional_argument?
          argument ||= items.at(items.index(item) + 1)
          check_valid_argument(option, argument)
          trash << argument

          if argument
            check_matching_argument(option, argument)
            option.argument_value = argument
            option.callback.call option.argument_value if option.callback
          else
            option.argument_value = nil
            check_optional_argument(option, flag)
          end
        elsif option.callback
          option.callback.call nil
        end
      else
        check_invalid_option(item, flag)
        block.call(item) if block_given? && !trash.include?(item)
      end
    end

    items.delete_if { |item| trash.include? item } if delete
    raise_if_invalid_options
    items
  end

  def check_valid_argument(option, argument)
    if !option.accepts_optional_argument? && argument =~ /\A--?.+\z/
      raise MissingArgumentError,
        "'#{option.key}' expects an argument, none given"
    end
  end

  def check_matching_argument(option, argument)
    if option.match && !argument.match(option.match)
      raise InvalidArgumentError,
        "'#{argument}' does not match #{option.match.inspect}"
    end
  end

  def check_optional_argument(option, flag)
    if option.accepts_optional_argument?
      option.callback.call nil if option.callback
    else
      raise MissingArgumentError,
        "'#{flag}' expects an argument, none given"
    end
  end

  def check_invalid_option(item, flag)
    @invalid_options << flag if item[/\A--?/] && @strict
  end

  def enable_multiple_switches(item)
    item[1..-1].split('').each do |switch|
      if option = @options[switch]
        if option.expects_argument?
          raise MissingArgumentError,
            "'-#{switch}' expects an argument, used in multiple_switch context"
        else
          option.argument_value = true
        end
      else
        if @strict
          raise InvalidOptionError, "Unknown option '-#{switch}'"
        end
      end
    end
  end

  def clean_options(args)
    options = []

    short = args.first.to_s.sub(/\A--?/, '')
    if short.size == 1
      options.push short
      args.shift
    else
      options.push nil
    end

    long = args.first
    boolean = long.is_a?(TrueClass) || long.is_a?(FalseClass)
    if !boolean && long.to_s =~ /\A(--?)?[a-zA-Z0-9_-]+\z/
      options.push args.shift.to_s.sub(/\A--?/, '')
    else
      options.push nil
    end

    options.push args.first.respond_to?(:to_sym) ? args.shift : nil
    options.push args.shift ? true : false # force true/false

    options
  end

  def raise_if_invalid_options
    return if !@strict || @invalid_options.empty?
    message = "Unknown option"
    message << 's' if @invalid_options.size > 1
    message << ' -- ' << @invalid_options.map { |o| "'#{o}'" }.join(', ')
    raise InvalidOptionError, message
  end
end
