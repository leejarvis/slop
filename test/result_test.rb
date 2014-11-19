require 'test_helper'

describe Slop::Result do
  before do
    @options = Slop::Options.new
    @options.bool "-v", "--verbose"
    @options.string "--name"
    @options.string "--unused"

    @result = @options.parse %w(foo -v --name lee argument)
  end

  describe "#to_hash" do
    it "returns option keys and values" do
      assert_equal({ verbose: true, name: "lee", unused: nil }, @result.to_hash)
    end
  end
end
