require 'helper'

class CommandTest < TestCase

  def setup
    @command = Slop::Command.new(:test)
  end

  def teardown
    @command = nil
  end

  def option(*args, &block)
    @command.option(*args, &block)
  end

  def options(*args)
    args.map { |a| option(*Array(a)) }
  end

  def parse(items, &block)
    @command.parse(items, &block)
  end

  test "option" do
    @command.option :user
    assert_kind_of Slop::Option, @command.options[:user]
  end

  test "command" do
    @command.command :add
    assert_kind_of Slop::Command, @command.commands[:add]
  end

  test "[]" do
    option "user="
    parse %w(--user Lee)
    assert_equal "Lee", @command[:user]
  end

  test "present?" do
    options "user", "verbose"
    parse %w(--user)
    assert @command.present?("user")
    assert @command.user?
    refute @command.verbose?
  end

  test "global?" do
    assert Slop.new.global?
    refute @command.global?
  end

  test "to_hash" do
    options "user=", "verbose", "other"
    parse %w(--user Lee --verbose)
    assert_equal({user: "Lee", verbose: nil, other: nil}, @command.to_hash)

    @command.command(:foo) { option :bar= }
    parse %w(foo --bar baz etc)
    assert_equal({user: "Lee", verbose: nil, other: nil, foo: {bar: "baz"}}, @command.to_hash)
  end

  test "short_flag_prefix" do
    assert_equal '@', Slop.new(short_flag_prefix: '@').short_flag_prefix
    assert_equal '-', @command.short_flag_prefix
  end

  test "long_flag_prefix" do
    assert_equal '!!', Slop.new(long_flag_prefix: '!!').long_flag_prefix
    assert_equal '--', @command.long_flag_prefix
  end

  test "flag_match" do
    assert @command.flag_match?("--user")
    refute @command.flag_match?("user")
    assert Slop.new(short_flag_prefix: '@').flag_match?('@foo')
  end

  test "clean_flag" do
    assert_equal "user", @command.clean_flag("--user")
    assert_equal "u", @command.clean_flag("-u")
    assert_equal "user", @command.clean_flag("user")
    assert_equal "@user", @command.clean_flag("@user")
  end

end
