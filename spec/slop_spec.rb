require File.expand_path('../../lib/slop', __FILE__)

describe Slop do
  before :all do
    @slop = Slop.new do
      option :v, :verbose, "Enable verbose mode"
    end
  end

  it "is enumerable" do
    Enumerable.instance_methods.each do |meth|
      @slop.respond_to?(meth).should be_true
    end
  end

  describe "banner" do
    it "adds a banner to the beginning of the help string" do
      o = Slop.new do
        banner("foo bar")
      end
      o.to_s.should == "foo bar\n"
    end
  end

  describe "::options" do
    it "should return the last set of options" do
      s = Slop.new { option(:f, :foo, "foo") }
      Slop.options.should == s.options
      p = Slop.new { option(:b, :bar, "bar") }
      Slop.options.should == p.options
    end
  end

  describe "option" do
    it "adds an option" do
      @slop.options.find do |opt|
        opt.flag == :v
      end.should be_kind_of(Slop::Option)
    end

    it "takes no more than 4 arguments" do
      lambda do
        Slop.new { option :a, :b, :c, :d, :e }
      end.should raise_error(ArgumentError, "Argument size must be no more than 4")
    end

    it "accepts a block which assigns an option callback" do
      s = Slop.parse("-v") do
        opt(:v, :version, "Display version") { "Version 1" }
      end
      s.option_for(:version).callback.should be_kind_of(Proc)
      s.option_for(:version).callback.call.should == "Version 1"
    end

    it "does not parse option values unless option.argument is true" do
      Slop.parse("--name Lee") { opt :name }.value_for(:name).should be_nil
      Slop.parse("--name Lee") { opt :name, true }.value_for(:name).should == "Lee"
      Slop.parse("--name Lee") { opt :name, :argument => true }.value_for(:name).should == "Lee"
    end
  end

  describe "options_hash" do
    it "returns a hash" do
      @slop.options_hash.should be_kind_of(Hash)
    end
  end

  describe "option_for" do
    it "returns an option" do
      @slop.option_for(:v).should be_kind_of(Slop::Option)
    end

    it "returns nil otherwise" do
      @slop.option_for(:nothing).should be_nil
    end
  end

  describe "value_for/[]" do
    it "returns the value of an option" do
      s = Slop.parse("--name Lee") do
        opt :n, :name, "Your name", true
      end
      s.value_for(:name).should == "Lee"
    end

    it "returns a default option if none is given" do
      Slop.new { opt :name, true, :default => "Lee" }.value_for(:name).should == "Lee"
      Slop.new { opt :name, true, :default => "Lee" }[:name].should == "Lee"
    end

    it "returns nil if an option does not exist" do
      Slop.new.value_for(:name).should be_nil
    end

    it "returns the value of an argument if one exists" do
      Slop.parse("foo") { arg(:name) }[:name].should == "foo"
    end

    it "prioritizes options over arguments" do
      o = Slop.parse("foo --foo bar") do
        arg(:foo)
        opt(:foo, true)
      end
      o[:foo].should == "bar"
    end
  end

  describe "argument" do
    it "adds an argument key" do
      s = Slop.new { argument(:filename) }
      s.instance_variable_get(:@argument_keys).should == [:filename]
    end
  end

  describe "arguments" do
    it "returns a hash" do
      Slop.new.arguments.should be_kind_of Hash
    end

    it "maps arguments to keys" do
      s = Slop.parse("foo.txt") { argument(:filename) }
      s.arguments[:filename].should == "foo.txt"
    end

    it "maps in order of keys" do
      s = Slop.parse("foo bar") { argument(:f, :b) }
      s.arguments.values_at(:f, :b).should == ["foo", "bar"]
    end

    it "returns nil for excessive keys mapped to no argument" do
      s = Slop.parse("") { argument(:foo) }
      s.arguments[:foo].should be_nil
    end
  end

  describe "parse" do
    it "returns self (Slop)" do
      Slop.parse.should be_kind_of(Slop)
    end

    it "parses a string" do
      Slop.parse("--name Lee") { opt :name, true }.value_for(:name).should == "Lee"
    end

    it "parses an array" do
      Slop.parse(%w"--name Lee") { opt :name, true }.value_for(:name).should == "Lee"
    end

    it "raises MissingArgumentError if no argument is given to a compulsory option" do
      lambda { Slop.parse("--name") { opt :name, true } }.should raise_error(Slop::MissingArgumentError, /name/)
    end

    it "does not raise MissingArgumentError if the optional attribute is true" do
      Slop.parse("--name") { opt :name, true, :optional => true }.value_for(:name).should be_nil
    end

    it "does not require argument to be true if optional is true" do
      Slop.parse("--name Lee") { opt :name, :optional => true }.value_for(:name).should == "Lee"
    end

    it "responds to both long options and single character flags" do
      Slop.parse("--name Lee") { opt :name, true }[:name].should == "Lee"
      Slop.parse("-n Lee") { opt :n, :name, true }[:name].should == "Lee"
    end
  end

  describe "options" do
    it "returns a set" do
      @slop.options.should be_kind_of Set
    end

    it "contains a set of Slop::Option" do
      @slop.options.each do |opt|
        opt.should be_kind_of(Slop::Option)
      end
    end
  end

  describe "argv" do
    it "contains all arguments which were unparsed by slop" do
      o = Slop.parse("lorem --foo bar ipsum") { opt(:foo, true) }
      o.argv.should == ["lorem", "ipsum"]
    end

    it "is empty if all arguments were sucked in by slop" do
      o = Slop.parse("--foo bar") { opt(:foo, true) }
      o.argv.should be_empty
    end

    it "contains arguments following options which do not require an argument" do
      o = Slop.parse("--foo bar") { opt(:foo) }
      o.argv.should == ["bar"]
    end
  end

  describe "pad_options (private method)" do
    before(:all) do
      @args = [
        [:n], [:n, :name], [:n, :name, "Desc"], [:n, :name, "Desc", true],
        [:name], [:n, "Desc"], [:n, true], [:name, "Desc"], [:name, true]
      ]
    end

    it "detects a description in place of an option, if one exists" do
      valid = [ "Description here", "Description!", "de#scription" ]
      invalid = [ "Description", "some-description" ] # these pass as valid options

      valid.each do |v|
        @slop.send(:pad_options, [:n, v]).should == [:n, nil, v, false]
      end

      invalid.each do |i|
        @slop.send(:pad_options, [:n, i]).should == [:n, i, nil, false]
      end
    end

    it "always returns an array of 4 elements" do
      @args.each do |arr|
        args = @slop.send(:pad_options, arr)
        args.should be_kind_of(Array)
        args.size.should == 4
      end
    end

    it "ends with a true or false class object" do
      @args.each do |arr|
        [true, false].include?(@slop.send(:pad_options, arr).last).should be_true
      end
    end
  end

  describe "flag_or_option?" do
    it "should be true if the string is a flag or an option" do
      good = ["-f", "--flag"]
      bad  = ["-flag", "f", "flag", "f-lag", "flag-", "--", "-"]
      good.each {|g| @slop.send(:flag_or_option?, g).should be_true }
      bad.each  {|b| @slop.send(:flag_or_option?, b).should be_false }
    end
  end

  describe "help string" do
    before :all do
      @o = Slop.new do
        banner("Usage: foo [options]")
        opt(:n, :name, "Your name")
        opt(:a, :age, "Your age")
      end
    end

    it "starts with a banner if one exists" do
      @o.to_s.split("\n").first.should == "Usage: foo [options]"
    end

    it "should include all options" do
      @o.each do |option|
        flag, opt, des = option.flag, option.option, option.description
        [flag, opt, des].each {|a| @o.to_s.include?(a.to_s).should be_true }
      end
    end
  end
end