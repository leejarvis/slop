require 'test_helper'

# The on_error call is tested herer.

describe 'on_error' do
  it "is called when there is a missing argument" do
    opts = Slop::Options.new
    opts.string "-n", "--name"
    opts.on_error do |ex|
      raise ArgumentError.new(ex.to_s)
    end

    begin
      opts.parse %w(--name)
    rescue ArgumentError => e
      assert_match(/-n, --name/, e.to_s)
    end
  end

  it "is called when there is a missing required option" do
    opts = Slop::Options.new
    opts.string "-n", "--name", required: true
    opts.on_error do |ex|
      raise ArgumentError.new(ex.to_s)
    end

    begin
      opts.parse %w()
    rescue ArgumentError => e
      assert_match(/missing required/, e.to_s)
    end
  end

  it "is called when there is an unknown option" do
    opts = Slop::Options.new
    opts.on_error do |ex|
      raise ArgumentError.new(ex.to_s)
    end

    begin
      opts.parse %w(--name)
    rescue ArgumentError => e
      assert_match(/unknown option/, e.to_s)
    end
  end
end
