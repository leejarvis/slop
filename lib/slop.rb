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
  VERSION = '1.8.0'

  # Parses the items from a CLI format into a friendly object
  #
  # @param [Array] items Items to parse into options.
  # @example Specifying three options to parse:
  #  opts = Slops.parse do
  #    on :v, :verbose, 'Enable verbose mode'
  #    on :n, :name,    'Your name'
  #    on :a, :age,     'Your age'
  #  end
  # @return [Slop] Returns an instance of Slop
  def self.parse(items=ARGV, options={}, &block)
    initialize_and_parse items, false, options, &block
  end

  # Identical to {Slop.parse}, but removes parsed options from the
  # original Array
  #
  # @return [Slop] Returns an instance of Slop
  def self.parse!(items=ARGV, options={}, &block)
    initialize_and_parse items, true, options, &block
  end

  # @return [Options]
  attr_reader :options

  # @return [Hash]
  attr_reader :commands

  # @overload banner=(string)
  #   Set the banner
  #   @param [String] string The text to set the banner to
  attr_writer :banner

  # @overload summary=(string)
  #   Set the summary
  #   @param [String] string The text to set the summary to
  attr_writer :summary

  # @overload description=(string)
  #   Set the description
  #   @param [String] string The text to set the description to
  attr_writer :description

  # @return [Integer] The length of the longest flag slop knows of
  attr_accessor :longest_flag

  # @option opts [Boolean] :help
  #   * Automatically add the `help` option
  #
  # @option opts [Boolean] :strict
  #   * Raises when a non listed option is found, false by default
  #
  # @option opts [Boolean] :multiple_switches
  #   * Allows `-abc` to be processed as the options 'a', 'b', 'c' and will
  #     force their argument values to true. By default Slop with parse this
  #     as 'a' with the argument 'bc'
  #
  # @option opts [String] :banner
  #   * The banner text used for the help
  #
  # @option opts [Proc, #call] :on_empty
  #   * Any object that respondes to `call` which is executed when Slop has
  #     no items to parse
  #
  # @option opts [IO, #puts] :io ($stderr)
  #   * An IO object for writing to when :help => true is used
  #
  # @option opts [Boolean] :exit_on_help (true)
  #   * When false and coupled with the :help option, Slop will not exit
  #     inside of the `help` option
  #
  # @option opts [Boolean] :ignore_case (false)
  #   * Ignore options case
  #
  # @option opts [Proc, #call] :on_noopts
  #   * Trigger an event when no options are found
  #
  # @option opts [Boolean] :autocreate (false)
  #   * Autocreate options depending on the Array passed to {#parse}
  #
  # @option opts [Boolean] :arguments (false)
  #   * Set to true to enable all specified options to accept arguments
  #     by default
  def initialize(*opts, &block)
    sloptions = opts.last.is_a?(Hash) ? opts.pop : {}
    sloptions[:banner] = opts.shift if opts[0].respond_to? :to_str
    opts.each { |o| sloptions[o] = true }

    @options = Options.new
    @commands = {}
    @execution_block = nil

    @longest_flag = 0
    @invalid_options = []

    @banner = sloptions[:banner]
    @strict = sloptions[:strict]
    @ignore_case = sloptions[:ignore_case]
    @multiple_switches = sloptions[:multiple_switches]
    @autocreate = sloptions[:autocreate]
    @arguments = sloptions[:arguments]
    @on_empty = sloptions[:on_empty]
    @on_noopts = sloptions[:on_noopts] || sloptions[:on_optionless]
    @sloptions = sloptions

    if block_given?
      block.arity == 1 ? yield(self) : instance_eval(&block)
    end

    if sloptions[:help]
      on :h, :help, 'Print this help message', :tail => true do
        (sloptions[:io] || $stderr).puts help
        exit unless sloptions[:exit_on_help] == false
      end
    end
  end

  # Set or return banner text
  #
  # @param [String] text Displayed banner text
  # @example
  #   opts = Slop.parse do
  #     banner "Usage - ruby foo.rb [arguments]"
  #   end
  # @return [String] The current banner
  def banner(text=nil)
    @banner = text if text
    @banner
  end

  # Set or return the summary
  #
  # @param [String] text Displayed summary text
  # @example
  #   opts = Slop.parse do
  #     summary "do stuff with more stuff"
  #   end
  # @return [String] The current summary
  def summary(text=nil)
    @summary = text if text
    @summary
  end

  # Set or return the description
  #
  # @param [String] text Displayed description text
  # @example
  #   opts = Slop.parse do
  #     description "This command does a lot of stuff with other stuff."
  #   end
  # @return [String] The current description
  def description(text=nil)
    @description = text if text
    @description
  end

  # Parse a list of options, leaving the original Array unchanged
  #
  # @param [Array] items A list of items to parse
  def parse(items=ARGV, &block)
    parse_items items, &block
  end

  # Parse a list of options, removing parsed options from the original Array
  #
  # @param [Array] items A list of items to parse
  def parse!(items=ARGV, &block)
    parse_items items, true, &block
  end

  # Enumerable interface
  def each(&block)
    @options.each(&block)
  end

  # @param [Symbol] key Option symbol
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

  # Specify an option with a short or long version, description and type
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
    options = args.last.is_a?(Hash) ? args.pop : {}

    short, long, desc, arg, extras = clean_options args
    options.merge!(extras)
    option = Option.new self, short, long, desc, arg, options, &block
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

    slop = Slop.new @sloptions.merge options
    @commands[label] = slop

    if block_given?
      block.arity == 1 ? yield(slop) : slop.instance_eval(&block)
    end

    slop
  end

  # Trigger an event when Slop has no values to parse
  #
  # @param [Object, #call] obj The object (which can be anything
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
  # @param [Object, #call] obj The object to be triggered (anything
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

  # Add an execution block (for commands)
  #
  # @example
  #   opts = Slop.new do
  #     command :foo do
  #       on :v, :verbose
  #
  #       execute { |o| p o.verbose? }
  #     end
  #   end
  #   opts.parse %w[foo --verbose] #=> true
  #
  # @param [Array] args The list of arguments to send to this command
  #   is invoked
  # @since 1.8.0
  # @yields [Slop] an instance of Slop for this command
  def execute(args=[], &block)
    if block_given?
      @execution_block = block
    elsif @execution_block.respond_to?(:call)
      @execution_block.call(self, args)
    end
  end

  # Returns the parsed list into a option/value hash
  #
  # @example
  #   opts.to_hash #=> { 'name' => 'Emily' }
  #
  #   # symbols!
  #   opts.to_hash(true) #=> { :name => 'Emily' }
  # @return [Hash]
  def to_hash(symbols=false)
    @options.to_hash symbols
  end
  alias :to_h :to_hash

  # Allows you to check whether an option was specified in the parsed list
  #
  # Merely sugar for `present?`
  #
  # @example
  #   #== ruby foo.rb -v
  #   opts.verbose? #=> true
  #   opts.name?    #=> false
  # @see Slop#present?
  # @return [Boolean] true if this option is present, false otherwise
  def method_missing(meth, *args, &block)
    super unless meth.to_s[-1, 1] == '?'
    present = present? meth.to_s.chomp '?'

    (class << self; self; end).instance_eval do
      define_method(meth) { present }
    end

    present
  end

  # Check if an option is specified in the parsed list
  #
  # Does the same as Slop#option? but a convenience method for unacceptable
  # method names
  #
  # @param [Object] The object name to check
  # @since 1.5.0
  # @return [Boolean] true if this option is present, false otherwise
  def present?(option_name)
    !!get(option_name)
  end

  # Returns the banner followed by available options listed on the next line
  #
  # @example
  #  opts = Slop.parse do
  #    banner "Usage - ruby foo.rb [arguments]"
  #    on :v, :verbose, "Enable verbose mode"
  #  end
  #  puts opts
  # @return [String] Help text.
  def to_s
    parts = []

    parts << banner if banner
    parts << summary if summary
    parts << wrap_and_indent(description, 80, 4) if description
    parts << "options:" if options.size > 0
    parts << options.to_help if options.size > 0

    parts.join("\n\n")
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
    elsif execute_command(items, delete)
      return items
    end

    trash = []
    ignore_all = false

    items.each_with_index do |item, index|
      item = item.to_s
      flag = item.sub(/\A--?/, '')

      if item == '--'
        trash << index
        ignore_all = true
      end

      next if ignore_all
      autocreate(flag, index, items) if @autocreate
      option, argument = extract_option(item, flag)
      next if @multiple_switches && !option

      if option
        option.count += 1
        trash << index
        next if option.forced
        option.argument_value = true

        if option.expects_argument? || option.accepts_optional_argument?
          argument ||= items.at(index + 1)
          trash << index + 1

          if !option.accepts_optional_argument? && flag?(argument)
            raise MissingArgumentError, "'#{option.key}' expects an argument, none given"
          end

          if argument
            if option.match && !argument.match(option.match)
              raise InvalidArgumentError, "'#{argument}' does not match #{option.match.inspect}"
            end

            option.argument_value = argument
            option.call option.argument_value unless option.omit_exec?(items)
          else
            option.argument_value = nil
            check_optional_argument!(option, flag)
          end
        else
          option.call unless option.omit_exec?(items)
        end
      else
        @invalid_options << flag if item[/\A--?/] && @strict
        block.call(item) if block_given? && !trash.include?(index)
      end
    end

    items.reject!.with_index { |o, i| trash.include?(i) } if delete
    raise_if_invalid_options!
    items
  end

  def check_optional_argument!(option, flag)
    if option.accepts_optional_argument?
      option.call
    else
      raise MissingArgumentError, "'#{flag}' expects an argument, none given"
    end
  end

  def raise_if_invalid_options!
    return if !@strict || @invalid_options.empty?
    message = "Unknown option#{'s' if @invalid_options.size > 1}"
    message << ' -- ' << @invalid_options.map { |o| "'#{o}'" }.join(', ')
    raise InvalidOptionError, message
  end

  def enable_multiple_switches(item)
    item[1..-1].each_char do |switch|
      if option = @options[switch]
        if option.expects_argument?
          raise MissingArgumentError, "'-#{switch}' expects an argument, used in multiple_switch context"
        end
        option.argument_value = true
      else
        raise InvalidOptionError, "Unknown option '-#{switch}'" if @strict
      end
    end
  end

  def wrap_and_indent(string, width, indentation)
    # Wrap and indent each paragraph
    string.lines.map do |paragraph|
      # Initialize
      lines = []
      line = ''

      # Split into words
      paragraph.split(/\s/).each do |word|
        # Begin new line if it's too long
        if (line + ' ' + word).length >= width
          lines << line
          line = ''
        end

        # Add word to line
        line << (line == '' ? '' : ' ' ) + word
      end
      lines << line

      # Join lines
      lines.map { |l| ' '*indentation + l }.join("\n")
    end.join("\n")
  end

  def extract_option(item, flag)
    if item[0, 1] == '-'
      option = @options[flag]
      option ||= @options[flag.downcase] if @ignore_case
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
        option, argument = @options[$1], $2
      when /\A--no-(.+)\z/
        option = @options[$1]
        option.force_argument_value(false) if option
      end
    end
    [option, argument]
  end

  def execute_command(items, delete)
    command = @commands.keys.find { |cmd| cmd.to_s == items[0].to_s }
    if command
      items.shift
      opts = @commands[command]
      delete ? opts.parse!(items) : opts.parse(items)
      opts.execute(items.reject { |i| i == '--' })
    end
  end

  def autocreate(flag, index, items)
    return if present? flag
    short, long = clean_options Array(flag)
    arg = (items[index + 1] && items[index + 1] !~ /\A--?/)
    @options << Option.new(self, short, long, nil, arg, {})
  end

  def clean_options(args)
    options = []
    extras = {}
    extras[:as] =args.find {|c| c.is_a? Class }
    args.delete(extras[:as])
    extras.delete(:as) if extras[:as].nil?

    short = args.first.to_s.sub(/\A--?/, '')
    if short.size == 1
      options.push short
      args.shift
    else
      options.push nil
    end

    long = args.first
    boolean = [true, false].include? long
    if !boolean && long.to_s =~ /\A(?:--?)?[a-z_-]+\s[A-Z\s\[\]]+\z/
      arg, help = args.shift.split(/ /, 2)
      options.push arg.sub(/\A--?/, '')
      extras[:optional] = help[0, 1] == '[' && help[-1, 1] == ']'
      extras[:help] = help
    elsif !boolean && long.to_s =~ /\A(?:--?)?[a-zA-Z][a-zA-Z0-9_-]+\z/
      options.push args.shift.to_s.sub(/\A--?/, '')
    else
      options.push nil
    end

    options.push args.first.respond_to?(:to_sym) ? args.shift : nil
    options.push @arguments ?  true : (args.shift ? true : false)
    options.push extras
  end

  def flag?(str)
    str =~ /\A--?[a-zA-Z][a-zA-Z0-9_-]*\z/
  end
end
