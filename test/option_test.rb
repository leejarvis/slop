require 'helper'

class OptionTest < TestCase

  def option(*args, &block)
    Slop::Option.build(Slop.new, args, &block)
  end

  def option_to_a(*args, &block)
    option = option(*args, &block)
    [option.short, option.long, option.description]
  end

  def option_as(as, value, config = {})
    config.merge!(as: as)
    option = Slop::Option.build(Slop.new, ["foo=", config])
    option.value = value
    option.value
  end

  test "::option" do
    assert_equal ['u', nil, nil], option_to_a('u')
    assert_equal ['u', nil, nil], option_to_a('u=')

    assert_equal [nil, 'user', nil], option_to_a('user')
    assert_equal [nil, 'user', nil], option_to_a('user=')

    assert_equal ['u', 'user', nil], option_to_a('u=', 'user')
    assert_equal ['u', 'user', nil], option_to_a('u', 'user=')

    assert_equal ['u', 'user', 'Foo'], option_to_a('u', 'user=', 'Foo')
    assert_equal [nil, 'user', 'Foo'], option_to_a('user', 'Foo')
    assert_equal ['u', nil, 'Foo Bar'], option_to_a('u', 'Foo Bar')

    assert_equal ['u', nil, 'Foo Bar'], option_to_a('u', 'Foo Bar', lorem: 'ipsum')
  end

  test "argument?" do
    assert option("user=").argument?
    refute option("user").argument?
  end

  test "optional_argument?" do
    assert option("user", optional_argument: true).optional_argument?
    refute option("user").optional_argument?
  end

  test "runner" do
    assert_equal "foo", option("user", runner: "foo").runner
    assert_kind_of Proc, option("user") { }.runner
    refute option("user").runner
  end

  test "call" do
    called = true
    option = option("user") { called = true }
    option.value = 'foo'
    assert_equal 'foo', option.call
    assert called
  end

  test "execute" do
    option = option("user")
    assert_equal 0, option.count
    option.execute
    assert_equal 1, option.count
  end

  test "key" do
    assert_equal "foo", option("f", "foo").key
    assert_equal "foo", option("foo").key
    assert_equal "f", option("f").key
  end

  test "help" do
    skip "not implemented"
  end

  test "default" do
    assert_equal nil, option("f").call
    assert_equal "foo", option("f", default: "foo").call
  end

  test "as(String)" do
    assert_equal "foo", option_as(String, "foo")
  end

  test "as(Symbol)" do
    assert_equal :foo, option_as(Symbol, "foo")
  end

  test "as(Array)" do
    assert_equal ["foo", "bar"], option_as(Array, "foo,bar")
    assert_equal ["foo", "bar"], option_as(Array, "foo:bar", delimiter: ":")
    assert_equal ["foo", "bar:baz"], option_as(Array, "foo:bar:baz", delimiter: ":", limit: 2)
  end

  test "as(Integer)" do
    assert_equal 1, option_as(Integer, "1")
  end

  test "as(Float)" do
    assert_equal 1.4, option_as(Float, "1.4")
  end

  test "as(Range)" do
    assert_equal((1..10),   option_as(Range, "1..10"))
    assert_equal((1..10),   option_as(Range, "1-10"))
    assert_equal((1..10),   option_as(Range, "1,10"))
    assert_equal((1...10),  option_as(Range, "1...10"))
    assert_equal((-1..10),  option_as(Range, "-1..10"))
    assert_equal((1..-10),  option_as(Range, "1..-10"))
    assert_equal((1..1),    option_as(Range, "1"))
    assert_equal((-1..10),  option_as(Range, "-1..10", optional_argument: true))
  end

  test "as(Custom)" do
    reverse = proc { |v| v.reverse }
    assert_equal "oof", option_as(reverse, "foo")
  end

end
