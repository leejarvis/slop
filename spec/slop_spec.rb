require File.expand_path('../../lib/slop', __FILE__)

describe Slop do
  before :all do
    @slop = Slop.new do
      option :v, :verbose, "Enable verbose mode"
    end
  end

  describe "option" do
    it "adds an option" do
      @slop.options.find do |opt|
        opt.flag == :v
      end.should be_kind_of(Slop::Option)
    end

    it "adds an option with a block to alter option attributes" do
      s = Slop.new do
        option :n, :name, "Set your name!", true do |o|
          o[:default] = "Lee"
        end
      end
      s.option_for(:name).default.should == "Lee"
    end

    it "takes no more than 4 arguments" do
      lambda do
        Slop.new { option :a, :b, :c, :d, :e }
      end.should raise_error(ArgumentError, "Argument size must be no more than 4")
    end

    it "does not parse option values unless option.argument is true" do
      Slop.parse("--name Lee") { opt :name }.value_for(:name).should be_nil
      Slop.parse("--name Lee") { opt :name, true }.value_for(:name).should == "Lee"
      Slop.parse("--name Lee") { opt :name, :argument => true }.value_for(:name).should == "Lee"
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

  describe "value_for" do
    it "returns the value of an option" do
      s = Slop.parse("--name Lee") do
        opt :n, :name, "Your name", true
      end
      s.value_for(:name).should == "Lee"
    end

    it "returns a default option if none is given" do
      Slop.new { opt :name, true, :default => "Lee" }.value_for(:name).should == "Lee"
    end

    it "returns nil if an option does not exist" do
      Slop.new.value_for(:name).should be_nil
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

end