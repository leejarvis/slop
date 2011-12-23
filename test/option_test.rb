require 'helper'

class OptionTest < TestCase
  def option(*args, &block)
    Slop.new.on(*args, &block)
  end

  test "expects_argument?" do
    assert option(:f=).expects_argument?
    assert option(:foo=).expects_argument?
    assert option(:foo, :argument => true).expects_argument?
  end

  test "accepts_optional_argument?" do
    refute option(:f=).accepts_optional_argument?
    assert option(:f=, :argument => :optional).accepts_optional_argument?
    assert option(:f, :optional_argument => true).accepts_optional_argument?
  end

  test "key" do
    assert_equal 'foo', option(:foo).key
    assert_equal 'foo', option(:f, :foo).key
    assert_equal 'f', option(:f).key
  end

  test "call" do
    foo = nil
    option(:f, :callback => proc { foo = "bar" }).call
    assert_equal "bar", foo
    option(:f) { foo = "baz" }.call
    assert_equal "baz", foo
    option(:f) { |o| assert_equal 1, o }.call(1)
  end
end