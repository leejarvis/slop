require 'helper'

class SlopTest < TestCase

  def build_option(*args)
    opt = Slop.new.send(:build_option, args)
    config = opt.config.reject { |k, v| v == Slop::Option::DEFAULT_OPTIONS[k] }
    [opt.short, opt.long, opt.description, config]
  end

  def temp_argv(items)
    old_argv = ARGV.clone
    ARGV.replace items
    yield
  ensure
    ARGV.replace old_argv
  end

  test "build_option" do
    assert_equal ['f', nil, nil, {}], build_option(:f)
    assert_equal [nil, 'foo', nil, {}], build_option(:foo)
    assert_equal ['f', nil, 'Some description', {}], build_option(:f, 'Some description')
    assert_equal ['f', 'foo', nil, {}], build_option(:f, :foo)

    # with arguments
    assert_equal ['f', nil, nil, {:argument=>true}], build_option('f=')
    assert_equal [nil, 'foo', nil, {:argument=>true}], build_option('foo=')
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

  test "::parse returns a Slop object" do
    assert_kind_of Slop, Slop.parse([])
  end

  test "parse" do
    slop = Slop.new
    assert_equal ['foo'], slop.parse(%w'foo')
    assert_equal ['foo'], slop.parse!(%w'foo')
  end

  test "parse!" do
    slop = Slop.new { on :foo= }
    assert_equal [], slop.parse!(%w'--foo bar')
    slop = Slop.new {  on :baz }
    assert_equal ['etc'], slop.parse!(%w'--baz etc')
  end

  test "new() accepts a hash of configuration options" do
    slop = Slop.new(:foo => :bar)
    assert_equal :bar, slop.config[:foo]
  end

  test "defaulting to ARGV" do
    temp_argv(%w/--name lee/) do
      opts = Slop.parse { on :name= }
      assert_equal 'lee', opts[:name]
    end
  end

  test "automatically adding the help option" do
    slop = Slop.new :help => true
    refute_empty slop.options
    assert_equal 'Display this help message.', slop.options.first.description
  end

  test ":arguments and :optional_arguments config options" do
    slop = Slop.new(:arguments => true) { on :foo }
    assert slop.fetch_option(:foo).expects_argument?

    slop = Slop.new(:optional_arguments => true) { on :foo }
    assert slop.fetch_option(:foo).accepts_optional_argument?
  end

  test "yielding non-options when a block is passed to parse()" do
    items = []
    opts = Slop.new { on :name= }
    opts.parse(%w/--name lee a b c/) { |v| items << v }
    assert_equal ['a', 'b', 'c'], items
  end

end