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

  test "to_hash" do
    assert_equal({
      :new => { :force => nil, :outdir => nil },
      :version => {}
    }, @commands.to_hash)
  end

  test "raising on unknown commands with :strict => true" do
    cmds = Slop::Commands.new(:strict => true)
    assert_raises(Slop::InvalidCommandError) { cmds.parse %w( abc ) }
  end

  test "adding global options" do
    cmds = Slop::Commands.new { global { on '--verbose' } }
    cmds.parse %w( --verbose )
    assert cmds[:global].verbose?
  end

  test "global options are always executed" do
    @commands.global { on 'foo=' }
    @commands.parse %w( new --force --foo bar )
    assert_equal 'bar', @commands[:global][:foo]
  end

  test "default options are only executed when there's nothing else" do
    @commands.default { on 'foo=' }
    @commands.parse %w( new --force --foo bar )
    assert_nil @commands[:default][:foo]
  end

  test "adding default options" do
    cmds = Slop::Commands.new { default { on '--verbose' } }
    cmds.parse %w( --verbose )
    assert cmds[:default].verbose?
  end

  test "on/global and default all return newly created slop instances" do
    assert_kind_of Slop, @commands.on('foo')
    assert_kind_of Slop, @commands.default
    assert_kind_of Slop, @commands.global
  end

  test "parse does nothing when there's nothing to parse" do
    assert @commands.parse []
  end

  test "parse returns the original array of items" do
    items = %w( foo bar baz )
    assert_equal items, @commands.parse(items)

    items = %w( new --force )
    assert_equal items, @commands.parse(items)
  end

  test "parse! removes options/arguments" do
    items = %w( new --outdir foo )
    @commands.parse!(items)
    assert_equal [], items
  end

end