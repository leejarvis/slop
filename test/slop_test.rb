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

  # test "default all options to take arguments" do
  #   slop = Slop.new(:arguments => true)
  #   opt1 = slop.on :foo
  #   opt2 = slop.on :bar, :argument => false
  #
  #   assert opt1.expects_argument?
  #   refute opt2.expects_argument?
  # end
end