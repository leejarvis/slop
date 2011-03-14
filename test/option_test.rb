require File.dirname(__FILE__) + '/helper'

class OptionTest < TestCase
  def option(*args, &block)
    Slop.new.option(*args, &block)
  end

  test 'expects an argument if argument is true' do
    assert option(:f, :foo, 'foo', true).expects_argument?
    assert option(:f, :argument => true).expects_argument?

    refute option(:f, :foo).expects_argument?
  end

  test 'accepts an optional argument if optional is true' do
    assert option(:f, :optional => true).accepts_optional_argument?
    assert option(:f, false, :optional => true).accepts_optional_argument?

    refute option(:f, true).accepts_optional_argument?
  end

  test 'has a callback when passed a block or callback option' do
    assert option(:f){}.has_callback?
    assert option(:callback => proc {}).has_callback?

    refute option(:f).has_callback?
  end

end