require 'helper'

class SlopTest < TestCase

  test "::parse!" do
    assert_kind_of Slop::Command, Slop.parse!(%w(foo))
  end

  test "::parse" do
    assert_kind_of Slop::Command, Slop.parse(%w(foo))
  end

  test "::new" do
    assert Slop.new.global?
  end

  test "errors" do
    begin
      Slop.parse(%w(--foo))
    rescue Slop::Error => e
      assert_kind_of Slop::Command, e.command
      assert_kind_of Slop::Command, e.opts
      assert e.message.include?("foo")
    end
  end

end
