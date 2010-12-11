require File.expand_path('../../lib/slop', __FILE__)

describe Slop::Option do

  describe "argument_value" do
    it "should return the default value if no value is found" do
      Slop::Option.new(:default => :foo).argument_value.should == :foo
    end

    it "is nil if there's no argument value and no default" do
      Slop::Option.new().argument_value.should be_nil
    end

    it "converts arguments into an integer with the :as => Integer flag" do
      opt = Slop::Option.new(:as => Integer)
      opt.argument_value = "1"
      opt.argument_value.should == 1
      opt.argument_value.should be_kind_of Integer
    end

    it "converts arguments into a symbol with the :as => Symbol flag" do
      opt = Slop::Option.new(:as => Symbol)
      opt.argument_value = "lee"
      opt.argument_value.should == :lee
      opt.argument_value.should be_kind_of Symbol
    end

    describe "with the :as Array option" do
      it "returns nil if no argument_value is set" do
        Slop::Option.new(:as => Array).argument_value.should be_nil
      end

      it "returns an Array" do
        opt = Slop::Option.new(:as => Array)
        opt.argument_value = "foo"
        opt.argument_value.should be_kind_of Array
      end

      it "uses , as the default delimiter" do
        opt = Slop::Option.new(:as => Array)
        opt.argument_value = "foo,bar"
        opt.argument_value.should == ["foo", "bar"]
        opt.argument_value = "foo:bar"
        opt.argument_value.should == ["foo:bar"]
      end

      it "can use a custom delimiter" do
        opt = Slop::Option.new(:as => Array, :delimiter => ':')
        opt.argument_value = "foo,bar"
        opt.argument_value.should == ["foo,bar"]
        opt.argument_value = "foo:bar"
        opt.argument_value = ["foo", "bar"]
      end

      it "can uses a custom limit" do
        opt = Slop::Option.new(:as => Array, :limit => 3)
        opt.argument_value = "foo,bar,baz,etc"
        opt.argument_value.should == ["foo", "bar", "baz,etc"]
      end
    end
  end

  describe "has_flag?" do
    it "is true if the option contains a flag" do
      Slop::Option.new().has_flag?(:n).should be_false
      Slop::Option.new(:flag => :n).has_flag?(:n).should be_true
    end
  end

  describe "has_option?" do
    it "is true if the option constains an.. option" do
      Slop::Option.new().has_option?(:name).should be_false
      Slop::Option.new(:option => :name).has_option?(:name).should be_true
    end
  end

  describe "has_default?" do
    it "is true if the option contains a default value" do
      Slop::Option.new(:default => 'Lee').has_default?.should be_true
      Slop::Option.new().has_default?.should be_false
    end
  end

  describe "has_switch?" do
    it "is true if the option contains a switchable value" do
      Slop::Option.new().has_switch?.should be_false
      Slop::Option.new(:switch => 'injekt').has_switch?.should be_true
    end
  end

  describe "has_callback?" do
    it "is true if the option has a callback" do
      Slop::Option.new().has_callback?.should be_false
      Slop::Option.new(:callback => proc { }).has_callback?.should be_true
    end
  end

  describe "execute_callback" do
    it "executes a callback" do
      opt = Slop::Option.new(:callback => proc { 'foo' })
      opt.execute_callback.should == 'foo'
    end
  end

  describe "requires_argument?" do
    it "returns true if the option requires an argument" do
      Slop::Option.new().requires_argument?.should be_false
      Slop::Option.new(:argument => true).requires_argument?.should be_true
    end
  end

  describe "optional_argument?" do
    it "returns true if the option argument is optional" do
      Slop::Option.new(:argument => true).optional_argument?.should be_false
      Slop::Option.new(:argument => true, :optional => true).optional_argument?.should be_true
      Slop::Option.new(:optional => true).optional_argument?.should be_true
    end
  end

  describe "[]" do
    it "should return an options value" do
      Slop::Option.new()[:foo].should be_nil
      Slop::Option.new(:foo => 'bar')[:foo].should == 'bar'
    end
  end

  describe "switch_argument_value" do
    it "replaces an options argument value with the switch value" do
      opt = Slop::Option.new(:default => 'foo', :switch => 'bar')
      opt.argument_value.should == 'foo'
      opt.switch_argument_value
      opt.argument_value.should == 'bar'
    end
  end

  describe "key" do
    it "returns the option if both a flag and option exist" do
      Slop::Option.new(:flag => :n, :option => :name).key.should == :name
    end

    it "returns the flag if there is no option" do
      Slop::Option.new(:flag => :n).key.should == :n
    end
  end

  describe "to_s" do
    before :all do
      o = Slop.new do
        opt(:n, nil, "Your name", true)
        opt(:a, :age, "Your age", :optional => true)
        opt(:verbose, "Enable verbose mode")
        opt(:p, :password, "Your password", true)
      end
      @opt = {}
      @opt[:flag] = o.option_for(:n)
      @opt[:optional] = o.option_for(:age)
      @opt[:option] = o.option_for(:verbose)
      @opt[:required] = o.option_for(:password)
    end

    it "starts with a tab space" do
      @opt[:flag].to_s[0].should == "\t"
    end

    it "displays a flag if one exists" do
      @opt[:flag].to_s[1, 2].should == "-n"
    end

    it "appends a comma to the flag if an option exists" do
      @opt[:flag].to_s[3].should_not == ","
      @opt[:optional].to_s[3].should == ","
    end

    it "displays an option if one exists" do
      @opt[:option].to_s[5, 9].should == "--verbose"
    end

    it "adds square brackes to the option if the argument is optional" do
      @opt[:optional].to_s[5, 11].should == "--age [age]"
    end

    it "adds angle brackets to the option if the argument is required" do
      @opt[:required].to_s[5, 21].should == "--password <password>"
    end
  end
end