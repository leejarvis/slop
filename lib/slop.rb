require 'slop/option'
require 'slop/version'

class Slop
  include Enumerable

  class MissingArgumentError < ArgumentError; end

  def self.parse(items, &block)
    slop = new(&block)
    slop.parse(items)
    slop
  end

  def initialize(&block)
    @options = []

    yield self if block_given?
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

private

  def parse_items(items, delete=false)
    items.each do |item|
      next unless item =~ /^/

      flag = item.to_s.sub(/^--?/, '')
      if flag.length == 1
        option = find { |option| option.short_flag == flag }
      else
        option = find { |option| option.long_flag == flag }
      end

      if option
        if option.expects_argument? || option.accepts_optional_argument?
          argument = items.at(items.index(item) + 1)
          items.delete(argument) if delete

          if argument
            option.callback.call(argument) if option.has_callback?
          else
            if option.accepts_optional_argument?
              option.callback.call(nil) if option.has_callback?
            else
              raise MissingArgumentError,
                "'#{flag}' expects an argument, none given"
            end
          end
        end
        items.delete(item) if delete
      end
    end
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

    if args.first.to_s =~ /\A(--?)?[a-zA-Z0-9_-]+\z/
      options.push args.shift.to_s.sub(/^--?/, '')
    else
      options.push nil
    end

    options.push args.first.respond_to?(:to_sym) ? args.shift : nil
    options.push args.shift ? true : false # force true/false

    options
  end

end