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
