require 'helper'

class OptionTest < TestCase
  def option(*args, &block)
    Slop.new.on(*args, &block)
  end

  def option_with_argument(*args, &block)
    options = args.shift
    slop = Slop.new
    option = slop.opt(*args)
    slop.parse(options)
    slop.options.find {|opt| opt.key == option.key }
  end

  def option_value(*args, &block)
    option_with_argument(*args, &block).value
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

  # type casting

  test "proc/custom type cast" do
    assert_equal 1, option_value(%w'-f 1', :f=, :as => proc {|x| x.to_i })
    assert_equal "oof", option_value(%w'-f foo', :f=, :as => proc {|x| x.reverse })
  end

  test "integer type cast" do
    assert_equal 1, option_value(%w'-f 1', :f=, :as => Integer)
  end

  test "symbol type cast" do
    assert_equal :foo, option_value(%w'-f foo', :f=, :as => Symbol)
  end

  test "range type cast" do
    assert_equal (1..10), option_value(%w/-r 1..10/, :r=, :as => Range)
    assert_equal (1..10), option_value(%w/-r 1-10/, :r=, :as => Range)
    assert_equal (1..10), option_value(%w/-r 1,10/, :r=, :as => Range)
    assert_equal (1...10), option_value(%w/-r 1...10/, :r=, :as => Range)
    assert_equal (-1..10), option_value(%w/-r -1..10/, :r=, :as => Range)
    assert_equal (1..-10), option_value(%w/-r 1..-10/, :r=, :as => Range)
  end

  test "array type cast" do
    assert_equal %w/lee john bill/, option_value(%w/-p lee,john,bill/, :p=, :as => Array)
    assert_equal %w/lee john bill/, option_value(%w/-p lee:john:bill/, :p=, :as => Array, :delimiter => ':')
    assert_equal %w/lee john,bill/, option_value(%w/-p lee,john,bill/, :p=, :as => Array, :limit => 2)
    assert_equal %w/lee john:bill/, option_value(%w/-p lee:john:bill/, :p=, :as => Array, :limit => 2, :delimiter => ':')
  end

  test "adding custom types" do
    opts = Slop.new
    opt = opts.on :f=, :as => :reverse
    opt.types[:reverse] = proc { |v| v.reverse }
    opts.parse %w'-f bar'
    assert_equal 'rab', opt.value
  end

  test "using a default value as fallback" do
    opts = Slop.new
    opt = opts.on :f, :argument => :optional, :default => 'foo'
    opts.parse %w'-f'
    assert_equal 'foo', opts[:f]
  end

  # end type casting tests
end