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
  VERSION = '1.5.5'

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

  # @return [Hash]
  attr_reader :commands

  # @overload banner=(string)
  #   Set the banner
  #   @param [String] string The text to set the banner to
  attr_writer :banner

  # @return [Integer] The length of the longest flag slop knows of
  attr_accessor :longest_flag

  # @param [Hash] options
  # @option opts [Boolean] :help Automatically add the `help` option
  # @option opts [Boolean] :strict Strict mode raises when a non listed
  #   option is found, false by default
  # @option opts [Boolean] :multiple_switches Allows `-abc` to be processed
  #   as the options 'a', 'b', 'c' and will force their argument values to
  #   true. By default Slop with parse this as 'a' with the argument 'bc'
  # @option opts [String] :banner The banner text used for the help
  # @option opts [Proc, #call] :on_empty Any object that respondes to `call`
  #   which is executed when Slop has no items to parse
  # @option opts [IO, #puts] :io ($stderr) An IO object for writing to when
  #   :help => true is used
  # @option opts [Boolean] :exit_on_help (true) When false and coupled with
  #   the :help option, Slop will not exit inside of the `help` option
  # @option opts [Boolean] :ignore_case (false) Ignore options case
  # @option opts [Proc, #call] :on_noopts Trigger an event when no options
  #   are found
  def initialize(*opts, &block)
    sloptions = {}
    sloptions.merge! opts.pop if opts.last.is_a? Hash
    sloptions[:banner] = opts.shift if opts[0].respond_to?(:to_str)
    opts.each { |o| sloptions[o] = true }

    @options = Options.new
    @commands = {}

    @longest_flag = 0
    @invalid_options = []

    @banner = sloptions[:banner]
    @strict = sloptions[:strict]
    @ignore_case = sloptions[:ignore_case]
    @multiple_switches = sloptions[:multiple_switches]
    @on_empty = sloptions[:on_empty]
    @on_noopts = sloptions[:on_noopts] || sloptions[:on_optionless]
    @sloptions = sloptions

    io = sloptions[:io] || $stderr
    eoh = true if sloptions[:exit_on_help].nil?

    if block_given?
      block.arity == 1 ? yield(self) : instance_eval(&block)
    end

    if sloptions[:help]
      on :h, :help, 'Print this help message', :tail => true do
        io.puts help
        exit if eoh
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
  # @return [String] The current banner.
  def banner(text=nil)
    @banner = text if text
    @banner
  end

  # Parse a list of options, leaving the original Array unchanged.
  #
  # @param [Array] items A list of items to parse
  def parse(items=ARGV, &block)
    parse_items items, &block
  end

  # Parse a list of options, removing parsed options from the original Array.
  #
  # @param [Array] items A list of items to parse
  def parse!(items=ARGV, &block)
    parse_items items, true, &block
  end

  # Enumerable interface
  def each(&block)
    @options.each(&block)
  end

  # @param [Symbol] key Option symbol.
  # @example
  #   opts[:name] #=> "Emily"
  #   opts.get(:name) #=> "Emily"
  # @return [Object] Returns the value associated with that option. If an
  #   option doesn't exist, a command will instead be searched for
  def [](key)
    option = @options[key]
    option ? option.argument_value : @commands[key]
  end
  alias :get :[]

  # Specify an option with a short or long version, description and type.
  #
  # @param [*] args Option configuration.
  # @option args [Symbol, String] :short_flag Short option name.
  # @option args [Symbol, String] :long_flag Full option name.
  # @option args [String] :description Option description for use in Slop#help
  # @option args [Boolean] :argument Specifies whether this option requires
  #   an argument
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

  # Namespace options depending on what command is executed
  #
  # @param [Symbol, String] label
  # @param [Hash] options
  # @example
  #   opts = Slop.new do
  #     command :create do
  #       on :v, :verbose
  #     end
  #   end
  #
  #   # ARGV is `create -v`
  #   opts.commands[:create].verbose? #=> true
  # @since 1.5.0
  # @return [Slop] a new instance of Slop namespaced to +label+
  def command(label, options={}, &block)
    if @commands[label]
      raise ArgumentError, "command `#{label}` already exists"
    end

    options = @sloptions.merge(options)
    slop = Slop.new(options)
    @commands[label] = slop

    if block_given?
      block.arity == 1 ? yield(slop) : slop.instance_eval(&block)
    end

    slop
  end

  # Trigger an event when Slop has no values to parse
  #
  # @param [Object, nil] proc The object (which can be anything
  #   responding to `call`)
  # @example
  #   Slop.parse do
  #     on_empty { puts 'No argument given!' }
  #   end
  # @since 1.5.0
  def on_empty(obj=nil, &block)
    @on_empty ||= (obj || block)
  end
  alias :on_empty= :on_empty

  # Trigger an event when the arguments contain no options
  #
  # @param [Object, nil] obj The object to be triggered (anything
  #   responding to `call`)
  # @example
  #   Slop.parse do
  #     on_noopts { puts 'No options here!' }
  #   end
  # @since 1.6.0
  def on_noopts(obj=nil, &block)
    @on_noopts ||= (obj || block)
  end
  alias :on_optionless :on_noopts

  # Returns the parsed list into a option/value hash.
  #
  # @example
  #   opts.to_hash #=> { 'name' => 'Emily' }
  #
  #   # symbols!
  #   opts.to_hash(true) #=> { :name => 'Emily' }
  # @return [Hash]
  def to_hash(symbols=false)
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
    present? meth.to_s.chomp '?'
  end

  # Check if an option is specified in the parsed list. Does the same as
  # Slop#option? but a convenience method for unacceptable method names.
  #
  # @param [Object] The object name to check
  # @since 1.5.0
  # @return [Boolean] true if this option is present
  def present?(option_name)
    !!get(option_name)
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

  def inspect
    "#<Slop config_options=#{@sloptions.inspect}\n  " +
    options.map(&:inspect).join("\n  ") + "\n>"
  end

  private

  class << self
    private

    def initialize_and_parse(items, delete, options, &block)
      if items.is_a?(Hash) && options.empty?
        options = items
        items = ARGV
      end

      slop = new(options, &block)
      delete ? slop.parse!(items) : slop.parse(items)
      slop
    end
  end

  def parse_items(items, delete=false, &block)
    if items.empty? && @on_empty.respond_to?(:call)
      @on_empty.call self
      return items
    elsif !items.any? {|i| i.to_s[/\A--?/] } && @on_noopts.respond_to?(:call)
      @on_noopts.call self
      return items
    end

    return if execute_command(items, delete)

    trash = []

    items.each_with_index do |item, index|
      item = item.to_s
      flag = item.sub(/\A--?/, '')
      option, argument = extract_option(item, flag)
      next if @multiple_switches

      if option
        option.count += 1
        trash << index
        next if option.forced
        option.argument_value = true

        if option.expects_argument? || option.accepts_optional_argument?
          argument ||= items.at(index + 1)
          check_valid_argument!(option, argument)
          trash << index + 1

          if argument
            check_matching_argument!(option, argument)
            option.argument_value = argument
            option.call option.argument_value
          else
            option.argument_value = nil
            check_optional_argument!(option, flag)
          end
        else
          option.call
        end
      else
        check_invalid_option!(item, flag)
        block.call(item) if block_given? && !trash.include?(index)
      end
    end

    items.reject!.with_index { |o, i| trash.include?(i) } if delete
    raise_if_invalid_options!
    items
  end

  def check_valid_argument!(option, argument)
    if !option.accepts_optional_argument? && argument =~ /\A--?.+\z/
      raise MissingArgumentError,
        "'#{option.key}' expects an argument, none given"
    end
  end

  def check_matching_argument!(option, argument)
    if option.match && !argument.match(option.match)
      raise InvalidArgumentError,
        "'#{argument}' does not match #{option.match.inspect}"
    end
  end

  def check_optional_argument!(option, flag)
    if option.accepts_optional_argument?
      option.call
    else
      raise MissingArgumentError,
        "'#{flag}' expects an argument, none given"
    end
  end

  def check_invalid_option!(item, flag)
    @invalid_options << flag if item[/\A--?/] && @strict
  end

  def raise_if_invalid_options!
    return if !@strict || @invalid_options.empty?
    message = "Unknown option"
    message << 's' if @invalid_options.size > 1
    message << ' -- ' << @invalid_options.map { |o| "'#{o}'" }.join(', ')
    raise InvalidOptionError, message
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

  def extract_option(item, flag)
    if item[/\A-/]
      option = @options[flag]
      if !option && @ignore_case
        option = @options[flag.downcase]
      end
    end
    unless option
      case item
      when /\A-[^-]/
        if @multiple_switches
          enable_multiple_switches(item)
        else
          flag, argument = flag.split('', 2)
          option = @options[flag]
        end
      when /\A--([^=]+)=(.+)\z/
        option = @options[$1]
        argument = $2
      when /\A--no-(.+)\z/
        option = @options[$1]
        option.force_argument_value(false) if option
      end
    end
    [option, argument]
  end

  def execute_command(items, delete)
    command = items[0]
    command = @commands.keys.find { |cmd| cmd.to_s == command.to_s }
    if @commands.key?(command)
      items.shift
      opts = @commands[command]
      delete ? opts.parse!(items) : opts.parse(items)
      true
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
    boolean = [true, false].include?(long)
    if !boolean && long.to_s =~ /\A(?:--?)?[a-zA-Z0-9_-]+\z/
      options.push args.shift.to_s.sub(/\A--?/, '')
    else
      options.push nil
    end

    options.push args.first.respond_to?(:to_sym) ? args.shift : nil
    options.push args.shift ? true : false # force true/false
  end
end
