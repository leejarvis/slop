require 'test_helper'

describe Slop::Parser do
  before do
    @options = Slop::Options.new
    @verbose = @options.bool "-v", "--verbose"
    @name    = @options.string "--name"
    @unused  = @options.string "--unused"
    @parser  = Slop::Parser.new(@options)
    @result  = @parser.parse %w(foo -v --name lee argument)
  end

  it "ignores everything after --" do
    @parser.reset.parse %w(-v -- --name lee)
    assert_equal [@verbose], @parser.used_options
  end

  it "parses flag=argument" do
    @options.integer "-p", "--port"
    @result.parser.reset.parse %w(--name=bob -p=123)
    assert_equal "bob", @result[:name]
    assert_equal 123, @result[:port]
  end

  describe "parsing grouped short flags" do
    before do
      @options.bool "-q", "--quiet"
    end

    it "parses boolean flags" do
      @result.parser.reset.parse %w(-qv)
      assert_equal true, @result.quiet?
      assert_equal true, @result.verbose?
    end
  end

  describe "#used_options" do
    it "returns all options that were parsed" do
      assert_equal [@verbose, @name], @parser.used_options
    end
  end

  describe "#unused_options" do
    it "returns all options that were not parsed" do
      assert_equal [@unused], @parser.unused_options
    end
  end
end
