require File.dirname(__FILE__) + '/helper'

class SlopTest < TestCase
  def clean_options(*args)
    Slop.new.send(:clean_options, args)
  end

  def parse(items, &block)
    Slop.parse(items, &block)
  end

  test 'includes Enumerable' do
    assert Slop.included_modules.include?(Enumerable)
  end

  test 'parse returns a Slop object' do
    slop = Slop.parse([])
    assert_kind_of Slop, slop
  end

  test 'enumerating options' do
    slop = Slop.new
    slop.opt(:f, :foo, 'foo')
    slop.opt(:b, :bar, 'bar')

    slop.each { |option| assert option }
  end

  test 'passing a block' do
    assert Slop.new {}
    slop = nil
    assert Slop.new {|s| slop = s }
    assert_kind_of Slop, slop
  end

  test 'setting the banner' do
    slop = Slop.new
    slop.banner = "foo bar"

    assert_equal "foo bar", slop.banner
    assert slop.to_s =~ /^foo bar/

    slop.banner = nil
    assert_equal "", slop.to_s
  end

  test '#parse does not remove parsed items' do
    items = %w/--foo/
    Slop.new { |opt| opt.on :foo }.parse(items)
    assert_equal %w/--foo/, items
  end

  test '#parse! removes parsed items' do
    items = %w/--foo/
    Slop.new { |opt| opt.on :foo }.parse!(items)
    assert_empty items
  end

  test 'the shit out of clean_options' do
    assert_equal(
      ['s', 'short', 'short option', false],
      clean_options('-s', '--short', 'short option')
    )

    assert_equal(
      [nil, 'long', 'long option only', true],
      clean_options('--long', 'long option only', true)
    )

    assert_equal(
      ['S', 'symbol', 'symbolize', false],
      clean_options(:S, :symbol, 'symbolize')
    )

    assert_equal(
      ['a', nil, 'alphabetical only', true],
      clean_options('a', 'alphabetical only', true)
    )

    assert_equal( # for description-less options
      [nil, 'optiononly', nil, false],
      clean_options('--optiononly')
    )

    assert_equal(['c', nil, nil, true], clean_options(:c, true))
    assert_equal(['c', nil, nil, false], clean_options(:c, false))
  end

  test '[] returns an options argument value or nil' do
    slop = Slop.new
    slop.opt :n, :name, true
    slop.parse %w/--name lee/

    assert_equal 'lee', slop[:name]
    assert_equal 'lee', slop[:n]
  end

  test 'arguments ending ? test for option existance' do
    slop = Slop.new
    slop.opt :v, :verbose
    slop.opt :d, :debug
    slop.parse %w/--verbose/

    assert slop[:verbose]
    assert slop.verbose?

    refute slop[:debug]
    refute slop.debug?
  end

  test 'raises if an option expects an argument and none is given' do
    slop = Slop.new
    slop.opt :name, true
    slop.opt :age, :optional => true

    assert_raises(Slop::MissingArgumentError, /name/) { slop.parse %w/--name/ }
    assert slop.parse %w/--name 'foo'/
  end

  test 'returning a hash of options' do
    slop = Slop.new
    slop.opt :name, true
    slop.opt :version
    slop.opt :V, :verbose, :default => false
    slop.parse %w/--name lee --version/

    assert_equal({'name' => 'lee', 'version' => true, 'verbose' => false}, slop.to_hash)
  end

  test 'iterating options' do
    slop = Slop.new
    slop.opt :a, :abc
    slop.opt :f, :foo

    assert_equal 2, slop.count
    slop.each {|opt| assert_kind_of Slop::Option, opt }
  end

  test 'printing help' do
    slop = Slop.new
    slop.banner = 'Usage: foo [options]'
    slop.parse

    assert slop.to_s =~ /^Usage: foo/
  end
end
