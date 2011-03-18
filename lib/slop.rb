require 'slop/option'
require 'slop/version'

class Slop
  include Enumerable

  class MissingArgumentError < ArgumentError; end
  class InvalidArgumentError < ArgumentError; end
  class InvalidOptionError < ArgumentError; end

  # Parses the items from a CLI format into a friendly object.
  #
  # @param [Array] items Items to parse into options.
  # @yield Specify available CLI arguments using Slop# methods such as Slop#banner and Slop#option
  # @return [Slop] Returns an instance of Slop.
  # @example Specifying three options to parse:
  #  opts = Slops.parse do
  #    on :v, :verbose, 'Enable verbose mode'
  #    on :n, :name,    'Your name'
  #    on :a, :age,     'Your age'
  #  end
  #  -------
  #  program.rb --verbose -n 'Emily' -a 25
  # @see Slop#banner
  # @see Slop#option
  def self.parse(items=ARGV, options={}, &block)
    if items.is_a?(Hash) && options.empty?
      options = items
      items = ARGV
    end

    slop = new(options, &block)
    slop.parse items
    slop
  end

  attr_reader :options
  attr_writer :banner
  attr_accessor :longest_flag

  # @param [Hash] options
  # @option options [Boolean] :help Automatically add the `help` option
  # @option options [Boolean] :strict Strict mode raises when a non listed
  #   option is found, false by default
  def initialize(options={}, &block)
    @options = Options.new
    @banner = nil
    @longest_flag = 0
    @strict = options[:strict]

    if block_given?
      block.arity == 1 ? yield(self) : instance_eval(&block)
    end

    if options[:help]
      on :h, :help, 'Print this help message', :tail => true do
        puts help
        exit
      end
    end
  end

  # Set or return banner text.
  #
  # @param [String] text Displayed banner text.
  # @return [String] Returns current banner.
  # @example
  #   opts = Slop.parse do
  #     banner "Usage - ruby foo.rb [arguments]"
  #   end
  # @see Slop#to_s
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
  # @parse items
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
  # @return [Object] Returns the object associated with that option.
  # @example
  #   opts[:name]
  #   #=> "Emily"
  # @see Slop#method_missing
  def [](key)
    option = @options[key]
    option ? option.argument_value : nil
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
  #     on :a, :age,  'Your age (optional)', :optional => true # Optional argument
  #     on :g, :gender, 'Your gender', :optional => false # Required argument
  #     on :V, :verbose, 'Run in verbose mode', :default => true # Runs verbose mode by default
  #     on :P, :people, 'Your friends', true, :as => Array # Required, list of people.
  #     on :h, :help, 'Print this help screen' do
  #       puts help
  #     end # Runs a block
  #   end
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
  # @return [Hash] Returns a hash with each specified option as a symbolic key with an associated value.
  # @example
  #   opts.to_hash
  #   #=> { 'name' => 'Emily' }
  #
  #   # symbols!
  #   opts.to_hash(true)
  #   #=> { :name => 'Emily' }
  def to_hash(symbols=nil)
    @options.to_hash(symbols)
  end
  alias :to_h :to_hash

  # Allows you to check whether an option was specified in the parsed list.
  #
  # @return [Boolean] Whether the desired option was specified.
  # @example
  #   #== ruby foo.rb -v
  #   opts.verbose?
  #   #=> true
  #   opts.name?
  #   #=> false
  # @see Slop#[]
  def method_missing(meth, *args, &block)
    meth.to_s[/\?$/] ? !!self[meth.to_s.chomp('?')] : super
  end

  # Returns the banner followed by available options listed on the next line.
  #
  # @return [String] Help text.
  # @example
  #  opts = Slop.parse do
  #    banner "Usage - ruby foo.rb [arguments]"
  #    on :v, :verbose, "Enable verbose mode"
  #  end
  #  opts.to_s
  #  #=> "Usage - ruby foo.rb [options]\n    -v, --verbose      Enable verbose mode"
  # @see Slop#banner
  def to_s
    banner = "#{@banner}\n" if @banner
    (banner || '') + options.to_help
  end
  alias :help :to_s

private

  def parse_items(items, delete=false, &block)
    trash = []

    items.each do |item|
      flag = item.to_s.sub(/^--?/, '')
      option = @options[flag]

      if option
        trash << item
        option.argument_value = true

        if option.expects_argument? || option.accepts_optional_argument?
          argument = items.at(items.index(item) + 1)
          trash << argument

          if argument
            if option.match && !argument.match(option.match)
              raise InvalidArgumentError,
                "'#{argument}' does not match #{option.match.inspect}"
            end

            option.argument_value = argument
            option.callback.call option.argument_value if option.callback
          else
            option.argument_value = nil
            if option.accepts_optional_argument?
              option.callback.call nil if option.callback
            else
              raise MissingArgumentError,
                "'#{flag}' expects an argument, none given"
            end
          end
        elsif option.callback
          option.callback.call nil
        end
      else
        if item[/^--?/] && @strict
          raise InvalidOptionError, "Unknown option -- '#{flag}'"
        end

        if block_given? && !trash.include?(item)
          block.call(item)
        end
      end
    end

    items.delete_if { |item| trash.include? item } if delete
    items
  end

  def clean_options(args)
    options = []

    short = args.first.to_s.sub(/^--?/, '')
    if short.size == 1
      options.push short
      args.shift
    else
      options.push nil
    end

    long = args.first
    boolean = long.is_a?(TrueClass) || long.is_a?(FalseClass)
    if !boolean && long.to_s =~ /\A(--?)?[a-zA-Z0-9_-]+\z/
      options.push args.shift.to_s.sub(/^--?/, '')
    else
      options.push nil
    end

    options.push args.first.respond_to?(:to_sym) ? args.shift : nil
    options.push args.shift ? true : false # force true/false

    options
  end

end
