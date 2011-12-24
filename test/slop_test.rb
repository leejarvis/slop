require 'helper'

class SlopTest < TestCase
  test "build_option" do
    build = proc { |*args| Slop.new.send(:build_option, args) }

    assert_equal ['f', nil, nil, {}], build[:f]
    assert_equal [nil, 'foo', nil, {}], build[:foo]
    assert_equal ['f', nil, 'Some description', {}], build[:f, 'Some description']
    assert_equal ['f', 'foo', nil, {}], build[:f, :foo]

    # with arguments
    assert_equal ['f', nil, nil, {:argument=>true}], build['f=']
    assert_equal [nil, 'foo', nil, {:argument=>true}], build['foo=']
  end

  test "fetch_option" do
    slop = Slop.new
    opt1 = slop.on :f, :foo
    opt2 = slop.on :bar

    assert_equal opt1, slop.fetch_option(:foo)
    assert_equal opt1, slop.fetch_option(:f)
    assert_equal opt2, slop.fetch_option(:bar)
    assert_equal opt2, slop.fetch_option('--bar')
    assert_nil slop.fetch_option(:baz)
  end

  test "default all options to take arguments" do
    slop = Slop.new(:arguments => true)
    opt1 = slop.on :foo
    opt2 = slop.on :bar, :argument => false

    assert opt1.expects_argument?
    refute opt2.expects_argument?
  end

  test "extract_option" do
    slop = Slop.new
    extract = proc { |flag| slop.send(:extract_option, flag) }
    slop.on :opt=

    assert_kind_of Array, extract['--foo']
    assert_equal 'bar', extract['--foo=bar'][1]
    assert_equal 'bar', extract['-f=bar'][1]
    assert_nil extract['--foo'][0]
    assert_kind_of Slop::Option, extract['--opt'][0]
    assert_equal false, extract['--no-opt'][1]
  end

  test "non-options yielded to parse()" do
    foo = nil
    slop = Slop.new
    slop.parse ['foo'] do |x| foo = x end
    assert_equal 'foo', foo
  end

  test "parse" do
    slop = Slop.new

    assert_equal ['foo'], slop.parse('foo')
  end
end