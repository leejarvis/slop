require 'slop/option'
require 'slop/version'

class Slop
  include Enumerable

  def self.parse(items=ARGV, &block)
    new(&block).parse(items)
  end

  def initialize(&block)
    @options = []

    yield self if block_given?
  end

  def parse(items)

    self
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

if $0 == __FILE__

  Slop.parse do |opt|
    opt.on(:n, :name, 'Your name', true) do |name|
      p name
    end
  end

end