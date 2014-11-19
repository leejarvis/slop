require 'test_helper'

describe Slop::Options do
  before do
    @options = Slop::Options.new
  end

  describe "#add" do
    it "defaults to string type" do
      assert_kind_of Slop::StringOption, @options.add("--foo")
    end

    it "accepts custom types" do
      module Slop; class FooOption < Option; end; end
      assert_kind_of Slop::FooOption, @options.add("--foo", type: :foo)
    end

    it "adds multiple flags" do
      option = @options.add("-f", "-F", "--foo")
      assert_equal %w(-f -F --foo), option.flags
    end

    it "accepts a trailing description" do
      option = @options.add("--foo", "fooey")
      assert_equal "fooey", option.desc
    end

    it "adds the option" do
      option = @options.add("--foo")
      assert_equal [option], @options.to_a
    end

    it "raises an error when a duplicate flag is used" do
      @options.add("--foo")
      assert_raises(ArgumentError) { @options.add("--foo") }
    end
  end

  describe "#method_missing" do
    it "uses the method name as an option type" do
      option = @options.string("--name")
      assert_kind_of Slop::StringOption, option
    end

    it "raises if a type doesn't exist" do
      assert_raises(NoMethodError) { @options.unknown }
    end
  end

  describe "#respond_to?" do
    it "handles custom types" do
      module Slop; class BarOption < Option; end; end
      assert @options.respond_to?(:bar)
    end
  end

  describe "#to_s" do
    it "is prefixed with the banner" do
      assert_match(/^usage/, @options.to_s)
    end

    it "aligns option strings" do
      @options.add "-f", "--foo", "fooey"
      @options.add "-s", "short"
      assert_match(/^    -f, --foo  fooey/, @options.to_s)
      assert_match(/^    -s         short/, @options.to_s)
    end

    it "can use a custom prefix" do
      @options.add "-f", "--foo"
      assert_match(/^ -f, --foo/, @options.to_s(prefix: " "))
    end
  end
end
