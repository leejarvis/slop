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

  def temp_stderr
    $stderr = StringIO.new
    yield $stderr.string
  ensure
    $stderr = STDERR
  end

  test "includes Enumerable" do
    assert_includes Slop.included_modules, Enumerable
  end

  test "enumerates Slop::Option objects in #each" do
    Slop.new { on :f; on :b; }.each { |o| assert_kind_of Slop::Option, o }
  end

  test "build_option" do
    assert_equal ['f', nil, nil, {}], build_option(:f)
    assert_equal [nil, 'foo', nil, {}], build_option(:foo)
    assert_equal ['f', nil, 'Some description', {}], build_option(:f, 'Some description')
    assert_equal ['f', 'foo', nil, {}], build_option(:f, :foo)

    # with arguments
    assert_equal ['f', nil, nil, {:argument=>true}], build_option('f=')
    assert_equal [nil, 'foo', nil, {:argument=>true}], build_option('foo=')
    assert_equal [nil, 'foo', nil, {:optional_argument=>true}], build_option('foo=?')
  end

  test "parsing option=value" do
    slop = Slop.new { on :foo= }
    slop.parse %w' --foo=bar '
    assert_equal 'bar', slop[:foo]
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

  test "on empty callback" do
    opts = Slop.new
    foo = nil
    opts.add_callback(:empty) { foo = "bar" }
    opts.parse []
    assert_equal "bar", foo
  end

  test "on no_options callback" do
    opts = Slop.new
    foo = nil
    opts.add_callback(:no_options) { foo = "bar" }
    opts.parse %w( --foo --bar etc hello )
    assert_equal "bar", foo
  end

  test "to_hash()" do
    opts = Slop.new { on :foo=; on :bar }
    opts.parse(%w'--foo hello --bar')
    assert_equal({ :foo => 'hello', :bar => nil }, opts.to_hash)
  end

  test "missing() returning all missing option keys" do
    opts = Slop.new { on :foo; on :bar }
    opts.parse %w'--foo'
    assert_equal ['bar'], opts.missing
  end

  test "autocreating options" do
    opts = Slop.new :autocreate => true
    opts.parse %w[ --foo bar --baz ]
    assert opts.fetch_option(:foo).expects_argument?
    assert opts.fetch_option(:foo).autocreated?
    assert_equal 'bar', opts.fetch_option(:foo).value
    refute opts.fetch_option(:baz).expects_argument?
  end

  test "option terminator" do
    opts = Slop.new { on :foo= }
    items = %w' foo -- --foo bar '
    opts.parse! items
    assert_equal %w' foo --foo bar ', items
  end

  test "raising an InvalidArgumentError when the argument doesn't match" do
    opts = Slop.new { on :foo=, :match => /^[a-z]+$/ }
    assert_raises(Slop::InvalidArgumentError) { opts.parse %w' --foo b4r '}
  end

  test "raising a MissingArgumentError when the option expects an argument" do
    opts = Slop.new { on :foo= }
    assert_raises(Slop::MissingArgumentError) { opts.parse %w' --foo '}
  end

  test "raising a MissingOptionError when a required option is missing" do
    opts = Slop.new { on :foo, :required => true }
    assert_raises(Slop::MissingOptionError) { opts.parse %w'' }
  end

  test "raising InvalidOptionError when strict mode is enabled and an unknown option appears" do
    opts = Slop.new :strict => true
    assert_raises(Slop::InvalidOptionError) { opts.parse %w'--foo' }
    assert_raises(Slop::InvalidOptionError) { opts.parse %w'-fabc' }
  end

  test "multiple_switches is enabled by default" do
    opts = Slop.new { on :f; on :b }
    opts.parse %w[ -fb ]
    assert opts.present?(:f)
    assert opts.present?(:b)
  end

  test "multiple_switches disabled" do
    opts = Slop.new(:multiple_switches => false) { on :f= }
    opts.parse %w[ -fabc123 ]
    assert_equal 'abc123', opts[:f]
  end

  test "setting/getting the banner" do
    opts = Slop.new :banner => 'foo'
    assert_equal 'foo', opts.banner

    opts = Slop.new
    opts.banner 'foo'
    assert_equal 'foo', opts.banner

    opts = Slop.new
    opts.banner = 'foo'
    assert_equal 'foo', opts.banner
  end

  test "get/[] fetching an options argument value" do
    opts = Slop.new { on :foo=; on :bar; on :baz }
    opts.parse %w' --foo hello --bar '
    assert_equal 'hello', opts[:foo]
    assert_nil opts[:bar]
    assert_nil opts[:baz]
  end

  test "checking for an options presence" do
    opts = Slop.new { on :foo; on :bar }
    opts.parse %w' --foo '
    assert opts.present?(:foo)
    refute opts.present?(:bar)
  end

  test "ignoring case" do
    opts = Slop.new { on :foo }
    opts.parse %w' --FOO bar '
    assert_nil opts[:foo]

    opts = Slop.new(:ignore_case => true) { on :foo= }
    opts.parse %w' --FOO bar '
    assert_equal 'bar', opts[:foo]
  end

  test "parsing an optspec and building options" do
    optspec = <<-SPEC
    ruby foo.rb [options]
    --
    v,verbose  enable verbose mode
    q,quiet   enable quiet mode
    n,name=    set your name
    p,pass=?   set your password
    SPEC
    opts = Slop.optspec(optspec.gsub(/^\s+/, ''))
    opts.parse %w[ --verbose --name Lee ]

    assert_equal 'Lee', opts[:name]
    assert opts.present?(:verbose)
    assert_equal 'enable quiet mode', opts.fetch_option(:quiet).description
    assert opts.fetch_option(:pass).accepts_optional_argument?
  end

  test "ensure negative integers are not processed as options" do
    items = %w(-1)
    Slop.parse!(items)
    assert_equal %w(-1), items
  end

  test "separators" do
    opts = Slop.new do
      on :foo
      separator "hello"
      on :bar
    end
    assert_equal "        --foo      \nhello\n        --bar      ", opts.help
  end

  test "printing help with :help => true" do
    temp_stderr do |string|
      opts = Slop.new(:help => true)
      opts.parse %w( --help )
      assert_equal "    -h, --help      Display this help message.\n", string
    end
  end

  test "option=value syntax does NOT consume following argument" do
    opts = Slop.new { on :foo=; on 'bar=?' }
    args = %w' --foo=bar baz --bar=zing hello '
    opts.parse!(args)
    assert_equal %w' baz hello ', args
  end

end
