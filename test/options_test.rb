require 'test_helper'

describe Slop::Options do
  before do
    @options = Slop::Options.new
  end

  describe "#on" do
    it "defaults to null type" do
      assert_kind_of Slop::NullOption, @options.on("--foo")
    end

    it "accepts custom types" do
      module Slop; class FooOption < Option; end; end
      assert_kind_of Slop::FooOption, @options.on("--foo", type: :foo)
    end

    it "adds multiple flags" do
      option = @options.on("-f", "-F", "--foo")
      assert_equal %w(-f -F --foo), option.flags
    end

    it "accepts a trailing description" do
      option = @options.on("--foo", "fooey")
      assert_equal "fooey", option.desc
    end

    it "adds the option" do
      option = @options.on("--foo")
      assert_equal [option], @options.to_a
    end

    it "raises an error when a duplicate flag is used" do
      @options.on("--foo")
      assert_raises(ArgumentError) { @options.on("--foo") }
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
    it "is prefixed with the default banner" do
      assert_match(/^usage/, @options.to_s)
    end

    it "aligns option strings" do
      @options.on "-f", "--foo", "fooey"
      @options.on "-s", "short"
      assert_match(/^    -f, --foo  fooey/, @options.to_s)
      assert_match(/^    -s         short/, @options.to_s)
    end

    it "can use a custom prefix" do
      @options.on "-f", "--foo"
      assert_match(/^ -f, --foo/, @options.to_s(prefix: " "))
    end

    it "ignores options with help: false" do
      @options.on "-x", "something", help: false
      refute_match(/something/, @options.to_s)
    end

    it "adds 'tail' options to the bottom of the help text" do
      @options.on "-h", "--help", tail: true
      @options.on "-f", "--foo"
      assert_match(/^    -h, --help/, @options.to_s.lines.last)
    end
  end

  describe "custom banner" do
    it "is prefixed with defined banner" do
      @options_config = Slop::Options.new({banner: "custom banner"})
      assert_match(/^custom banner/, @options_config.to_s) 
    end
    it "banner is disabled" do
      @options_config = Slop::Options.new({banner: false})
      assert_match("", @options_config.to_s)
    end
  end
end
