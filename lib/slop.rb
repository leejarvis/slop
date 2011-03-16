require 'slop/option'
require 'slop/version'

class Slop
  include Enumerable

  class MissingArgumentError < ArgumentError; end

  def self.parse(items=ARGV, &block)
    slop = new(&block)
    slop.parse(items)
    slop
  end

  attr_reader :options
  attr_writer :banner

  def initialize(&block)
    @options = Options.new
    @banner = nil
    if block_given?
      block.arity == 1 ? yield(self) : instance_eval(&block)
    end
  end

  def banner(text=nil)
    @banner = text if text
    @banner
  end

  def parse(items=ARGV)
    parse_items(items)
  end

  def parse!(items=ARGV)
    parse_items(items, true)
  end

  # Enumerable interface
  def each
    return enum_for(:each) unless block_given?
    @options.each { |option| yield option }
  end

  def [](key)
    option = @options[key]
    option ? option.argument_value : nil
  end

  # :short_flag
  # :long_flag
  # :description
  # :argument
  def option(*args, &block)
    options = args.pop if args.last.is_a?(Hash)
    options ||= {}

    option = Option.new(*clean_options(args), options, &block)
    @options << option

    option
  end
  alias :opt :option
  alias :on :option

  def to_hash
    @options.to_hash
  end

  def method_missing(meth, *args, &block)
    if meth.to_s =~ /\?$/
      !!self[meth.to_s.chomp('?')]
    else
      super
    end
  end

  def to_s
    banner = "#{@banner}\n" if @banner
    banner + options.map(&:to_s).join("\n")
  end
  alias :help :to_s

private

  def parse_items(items, delete=false)
    trash = []

    items.each do |item|

      flag = item.to_s.sub(/^--?/, '')
      if flag.length == 1
        option = find { |option| option.short_flag == flag }
      else
        option = find { |option| option.long_flag == flag }
      end

      if option
        option.argument_value = true

        if option.expects_argument? || option.accepts_optional_argument?
          argument = items.at(items.index(item) + 1)
          trash << argument if delete && argument !~ /^--?/

          if argument
            option.argument_value = argument
            option.callback.call(option.argument_value) if option.has_callback?
          else
            if option.accepts_optional_argument?
              option.callback.call(nil) if option.has_callback?
            else
              raise MissingArgumentError,
                "'#{flag}' expects an argument, none given"
            end
          end
        elsif option.has_callback?
          option.callback.call(nil)
        end
        trash << item if delete
      end
    end
    items.delete_if { |item| trash.include? item }
  end

  # @param [Array] args
  # @return [Array]
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
    if !long.is_a?(TrueClass) && !long.is_a?(FalseClass) && long.to_s =~ /\A(--?)?[a-zA-Z0-9_-]+\z/
      options.push args.shift.to_s.sub(/^--?/, '')
    else
      options.push nil
    end

    options.push args.first.respond_to?(:to_sym) ? args.shift : nil
    options.push args.shift ? true : false # force true/false

    options
  end

end
