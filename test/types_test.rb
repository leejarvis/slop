require 'test_helper'

describe Slop::BoolOption do
  before do
    @options  = Slop::Options.new
    @verbose  = @options.bool "--verbose"
    @quiet    = @options.bool "--quiet"
    @inversed = @options.bool "--inversed", default: true
    @bloc     = @options.bool("--bloc"){|val| (@bloc_val ||= []) << val}
    @result   = @options.parse %w(--verbose --no-inversed
                                  --bloc --no-bloc)
  end

  it "returns true if used" do
    assert_equal true, @result[:verbose]
  end

  it "returns false if not used" do
    assert_equal false, @result[:quiet]
  end

  it "can be inversed via --no- prefix" do
    assert_equal false, @result[:inversed]
  end

  it "will invert the value passed to &block via --no- prefix" do
    assert_equal [true, false], @bloc_val
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
    @result.parser.parse %w(--age hello)
    assert_equal nil, @result[:age]
  end
end

describe Slop::FloatOption do
  before do
    @options = Slop::Options.new
    @apr     = @options.float "--apr"
    @apr_value = 2.9
    @result  = @options.parse %W(--apr #{@apr_value})
  end

  it "returns the value as a float" do
    assert_equal @apr_value, @result[:apr]
  end

  it "returns nil for non-numbers by default" do
    @result.parser.parse %w(--apr hello)
    assert_equal nil, @result[:apr]
  end
end

describe Slop::ArrayOption do
  before do
    @options = Slop::Options.new
    @files   = @options.array "--files"
    @multi   = @options.array "-M", delimiter: nil
    @delim   = @options.array "-d", delimiter: ":"
    @limit   = @options.array "-l", limit: 2
    @result  = @options.parse %w(--files foo.txt,bar.rb)
  end

  it "defaults to []" do
    assert_equal [], @result[:d]
  end

  it "parses comma separated args" do
    assert_equal %w(foo.txt bar.rb), @result[:files]
  end

  it "collects multiple option values" do
    @result.parser.parse %w(--files foo.txt --files bar.rb)
    assert_equal %w(foo.txt bar.rb), @result[:files]
  end

  it "collects multiple option values with no delimiter" do
    @result.parser.parse %w(-M foo,bar -M bar,qux)
    assert_equal %w(foo,bar bar,qux), @result[:M]
  end

  it "can use a custom delimiter" do
    @result.parser.parse %w(-d foo.txt:bar.rb)
    assert_equal %w(foo.txt bar.rb), @result[:d]
  end

  it "can use a custom limit" do
    @result.parser.parse %w(-l foo,bar,baz)
    assert_equal ["foo", "bar,baz"], @result[:l]
  end
end

describe Slop::NullOption do
  before do
    @options = Slop::Options.new
    @version = @options.null('--version')
    @result  = @options.parse %w(--version)
  end

  it 'has a return value of true' do
    assert_equal true, @result[:version]
  end

  it 'is not included in to_hash' do
    assert_equal({}, @result.to_hash)
  end
end

describe Slop::RegexpOption do
  before do
    @options       = Slop::Options.new
    @exclude       = @options.regexp "--exclude"
    @exclude_value = "redirect|news"
    @result        = @options.parse %W(--exclude #{@exclude_value})
  end

  it "returns the value as a Regexp" do
    assert_equal Regexp.new(@exclude_value), @result[:exclude]
  end
end
