require 'helper'

class CommandsTest < TestCase

  def setup
    @commands = Slop::Commands.new do
      on 'new' do
        on '--force', 'Force creation'
        on '--outdir=', 'Output directory'
      end

      on 'version' do
        add_callback(:empty) { 'version 1' }
      end
    end
  end

  test "it nests instances of Slop" do
    assert_empty Slop::Commands.new.commands
    @commands.commands.each_value { |k| assert_kind_of Slop, k }
  end

  test "accessing Slop instances via get/[]" do
    assert_kind_of Slop, @commands['new']
    assert_kind_of Slop, @commands[:new]
    assert_nil @commands[:unknown]
    assert_equal 'Force creation', @commands[:new].fetch_option(:force).description
  end

end