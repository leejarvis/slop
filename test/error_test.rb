require 'test_helper'

# All raised errors tested here

describe Slop::MissingArgument do
  it "raises when an argument is missing" do
    opts = Slop::Options.new
    opts.string "-n", "--name"
    assert_raises(Slop::MissingArgument) { opts.parse %w(--name) }
  end

  it "does not raise when errors are suppressed" do
    opts = Slop::Options.new(suppress_errors: true)
    opts.string "-n", "--name"
    opts.parse %w(--name)
  end
end

describe Slop::UnknownOption do
  it "raises when an option is unknown" do
    opts = Slop::Options.new
    opts.string "-n", "--name"
    assert_raises(Slop::UnknownOption) { opts.parse %w(--foo) }
  end

  it "does not raise when errors are suppressed" do
    opts = Slop::Options.new(suppress_errors: true)
    opts.string "-n", "--name"
    opts.parse %w(--foo)
  end
end
