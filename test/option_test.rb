require 'test_helper'

describe Slop::Option do
  def option(*args)
    Slop::Option.new(*args)
  end

  describe "#flag" do
    it "returns the flags joined by a comma" do
      assert_equal "-f, --bar", option(%w(-f --bar), nil).flag
      assert_equal "--bar", option(%w(--bar), nil).flag
    end
  end

  describe "#key" do
    it "uses the last flag and strips trailing hyphens" do
      assert_equal :foo, option(%w(-f --foo), nil).key
    end

    it "converts dashes to underscores to make multi-word options symbol-friendly" do
      assert_equal :foo_bar, option(%w(-f --foo-bar), nil).key
    end

    it "can be overridden" do
      assert_equal :bar, option(%w(-f --foo), nil, key: "bar").key
    end
  end

  describe "#metavar" do
    it "will be nil unless #expects_argument?" do
      assert_nil Slop::BoolOption.new(%w(--foo), nil).metavar
    end
    it "will be the uppercased name of the longest flag by default" do
      assert_equal "FOO", Slop::Option.new(%w(--foo -f), nil).metavar
    end
    it "can be overridden" do
      assert_equal "BAR", Slop::Option.new(%w(--foo), nil, metavar: 'BAR').metavar
    end
    it "will be surrounded by square brackets if it has a default" do
      assert_equal "[FOO]", Slop::Option.new(%w(--foo), nil, default: "bar").metavar
    end
  end
end
