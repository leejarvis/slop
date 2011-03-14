require File.dirname(__FILE__) + '/helper'

class SlopTest < TestCase
  def clean_options(*args)
    Slop.new.send(:clean_options, args)
  end

  test 'includes Enumerable' do
    assert Slop.included_modules.include?(Enumerable)
  end

  test 'parse returns a Slop object' do
    slop = Slop.parse(nil)
    assert_kind_of Slop, slop
  end

  test 'enumerating options' do
    slop = Slop.new
    slop.opt(:f, :foo, 'foo')
    slop.opt(:b, :bar, 'bar')

    slop.each { |option| assert option }
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
  end
end