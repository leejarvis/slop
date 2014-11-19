require 'test_helper'

describe Slop::BoolOption do
  before do
    @options = Slop::Options.new
    @age     = @options.bool "--verbose"
    @result  = @options.parse %w(--verbose)
  end

  it "returns true if used" do
    assert_equal true, @result[:verbose]
  end
end

describe Slop::IntegerOption do
  before do
    @options = Slop::Options.new
    @age     = @options.integer "--age"
    @result  = @options.parse %w(--age 20)
  end

  it "returns the value as an integer" do
    assert_equal 20, @result[:age]
  end

  it "returns nil for non-numbers by default" do
    @result.parser.reset.parse %w(--age hello)
    assert_equal nil, @result[:age]
  end
end

describe Slop::ArrayOption do
  before do
    @options = Slop::Options.new
    @files   = @options.array "--files"
    @delim   = @options.array "-d", delimiter: ":"
    @result  = @options.parse %w(--files foo.txt,bar.rb)
  end

  it "parses comma separated args" do
    assert_equal %w(foo.txt bar.rb), @result[:files]
  end

  it "collects multiple option values" do
    @result.parser.reset.parse %w(--files foo.txt --files bar.rb)
    assert_equal %w(foo.txt bar.rb), @result[:files]
  end

  it "can use a custom delimiter" do
    @result.parser.reset.parse %w(-d foo.txt:bar.rb)
    assert_equal %w(foo.txt bar.rb), @result[:d]
  end
end

