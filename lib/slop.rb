require 'slop/commands'
require 'slop/command'
require 'slop/option_builder'
require 'slop/processor'
require 'slop/options'
require 'slop/option'
require 'slop/error'

class Slop
  VERSION = "4.0.0"

  class << self
    attr_accessor :config
  end

  self.config = {
    strict:            true,
    help:              true,
    ignore_case:       false,
    multiple_switches: true
  }

  def self.parse!(items = ARGV, config = {}, &block)
    Slop.new(config, &block).parse!(items)
  end

  def self.parse(items = ARGV, config = {}, &block)
    parse!(items.dup, config, &block)
  end

  attr_reader :command

  def initialize(config = {}, &block)
    @command = Command.new(:_global_, config, &block)
  end

  # Delegate methods to command object

  def respond_to_missing?(meth, include_private = false)
    command.respond_to_missing?(meth) || super
  end

  def method_missing(meth, *args, &block)
    if command.respond_to?(meth)
      command.send(meth, *args, &block)
    else
      super
    end
  end

end
