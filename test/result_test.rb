require 'test_helper'

describe Slop::Result do
  before do
    @options = Slop::Options.new
    @verbose = @options.bool "-v", "--verbose"
    @name    = @options.string "--name"
    @unused  = @options.string "--unused"
    @result  = @options.parse %w(foo -v --name lee argument)
  end

  it "increments option count" do
    # test this here so it's more "full stack"
    assert_equal 1, @verbose.count
    @result.parser.reset.parse %w(-v --verbose)
    assert_equal 2, @verbose.count
  end

  describe "#[]" do
    it "returns an options value" do
      assert_equal "lee", @result["name"]
      assert_equal "lee", @result[:name]
      assert_equal "lee", @result["--name"]
    end
  end

  describe "#option" do
    it "returns an option by flag" do
      assert_equal @verbose, @result.option("--verbose")
      assert_equal @verbose, @result.option("-v")
    end

    it "ignores prefixed hyphens" do
      assert_equal @verbose, @result.option("verbose")
      assert_equal @verbose, @result.option("-v")
    end

    it "returns nil if nothing is found" do
      assert_equal nil, @result.option("foo")
    end
  end

  describe "#to_hash" do
    it "returns option keys and values" do
      assert_equal({ verbose: true, name: "lee", unused: nil }, @result.to_hash)
    end
  end
end
