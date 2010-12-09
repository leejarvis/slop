require 'set'

require 'slop/option'

class Slop
  include Enumerable

  VERSION = '0.1.8'

  # Raised when an option expects an argument and none is given
  class MissingArgumentError < ArgumentError; end

  # @return [Set]
  attr_reader :options

  # @return [Set] the last set of options used
  def self.options
    @@options
  end

  # Sugar for new(..).parse(stuff)
  def self.parse(values=[], &blk)
    new(&blk).parse(values)
  end

  def initialize(&blk)
    @options = Set.new
    @@options = @options
    instance_eval(&blk) if block_given?
  end

  # add an option
  def option(*args, &blk)
    opts = args.pop if args.last.is_a?(Hash)
    opts ||= {}

    if args.size > 4
      raise ArgumentError, "Argument size must be no more than 4"
    end

    attributes = [:flag, :option, :description, :argument]
    options = Hash[attributes.zip(pad_options(args))]
    options.merge!(opts)
    options[:callback] = blk if block_given?

    @options << Option.new(options)
  end
  alias :opt :option
  alias :o :option

  # add an argument
  def argument(*args)

  end
  alias :arg :argument
  alias :args :argument
  alias :arguments :argument

  # Parse an Array (usually ARGV) of options
  #
  # @param [Array, #split] Array or String of options to parse
  # @raise [MissingArgumentError] raised when a compulsory argument is missing
  def parse(values=[])
    values = values.split(/\s+/) if values.respond_to?(:split)

    values.each do |value|
      if flag_or_option?(value)
        opt   = value.size == 2 ? value[1] : value[2..-1]
        index = values.index(value)

        next unless option = option_for(opt) # skip unknown values for now

        option.execute_callback if option.has_callback?
        option.switch_argument_value if option.has_switch?

        if option.requires_argument?
          value = values.at(index + 1)

          unless option.optional_argument?
            if not value or flag_or_option?(value)
              raise MissingArgumentError,
                  "#{option.key} requires a compulsory argument, none given"
              end
          end

          unless not value or flag_or_option?(value)
            option.argument_value = values.delete_at(values.index(value))
          end
        end
      else
        # not a flag or option, parse as an argument
      end
    end

    self
  end

  # A simple Hash of options with option labels or flags as keys
  # and option values as.. values.
  #
  # @return [Hash]
  def options_hash
    out = {}
    options.each do |opt|
      if opt.requires_argument? or opt.has_default?
        out[opt.key] = opt.argument_value || opt.default
      end
    end
    out
  end
  alias :to_hash :options_hash
  alias :to_h :options_hash

  # Find an option using its flag or label
  #
  # @example
  #   s = Slop.new do
  #     option(:n, :name, "Your name")
  #   end
  #
  #   s.option_for(:name).description #=> "Your name"
  #
  # @return [Option] the option flag or label
  def option_for(flag)
    find do |opt|
      opt.has_flag?(flag) || opt.has_option?(flag)
    end
  end

  # Find an options argument using the option name.
  # Essentially this is the same as `s.options_hash[:name]`
  #
  # @example When passing --name Lee
  #   s = Slop.new do
  #     option(:n, :name, true)
  #   end
  #
  #   s.value_for(:name) #=> "Lee"
  #
  def value_for(flag)
    return unless option = option_for(flag)
    option.argument_value
  end
  alias :[] :value_for

  # Implement #each so our options set is enumerable
  def each
    return enum_for(:each) unless block_given?
    @options.each { |opt| yield opt }
  end

  private

  def flag_or_option?(flag)
    return unless flag && flag.size > 1

    if flag[1] == '-'
      return flag[0] == '-' && flag[3]
    elsif flag[0] == '-'
      return !flag[3]
    end
  end

  def pad_options(args)
    args.unshift nil if args.first.nil? || args.first.size > 1
    args.push nil if args.size < 2
    args.push nil if args.size == 2
    args.push false if args.size == 3
    args[2..3] = [nil, true] if args[2] == true
    args
  end
end
