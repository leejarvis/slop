unless Object.const_defined? 'Slop'
  $:.unshift File.expand_path('../../lib', __FILE__)
  require 'slop'
end

require 'minitest/autorun'
require 'stringio'

begin
  require 'turn'
rescue LoadError
end

class TestCase < MiniTest::Unit::TestCase
  def self.test(name, &block)
    test_name = "test_#{name.gsub(/\s+/, '_')}".to_sym
    defined = instance_method(test_name) rescue false
    raise "#{test_name} is already defined in #{self}" if defined
    if block_given?
      define_method(test_name, &block)
    else
      define_method(test_name) do
        flunk "No implementation provided for #{name}"
      end
    end
  end
end