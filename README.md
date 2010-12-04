Slop
====

Slop is a simple option collector with an easy to remember syntax and friendly API.

**NOTE** This software is still unstable, it contains bugs and lacks core
features

Installation
------------

### Rubygems

    gem install slop

### GitHub

    git clone git://github.com/injekt/slop.git
    cd slop
    gem build slop.gemspec
    gem install slop-0.1.6.gem
    
Features Overview
-----------------

 - Callbacks
 - Casting
 - Lists

Usage
-----

    s = Slop.parse(ARGV) do
      option(:v, :verbose, "Enable verbose mode", :default => false)
      option(:n, :name, "Your name", true) # compulsory argument
      option(:c, :country, "Your country", :argument => true) # the same thing

      option(:a, :age, "Your age", true, :optional => true) # optional argument
      option(:address, "Your address", :optional => true)   # the same

      # shortcut option aliases
      opt(:height, "Your height")
      o(:weight, "Your weight")
    end

    # using `--name Lee -a 100`
    s.options_hash #=> {:verbose=>false, :name=>"Lee", :age=>"100", :address=>nil}
    s.value_for(:name) #=> "Lee"

    # or grab the Option object directly
    option = s.option_for(:name)
    option.description #=> "Your name"

    # You can also use switch values to set options according to arguments
    s = Slop.parse(ARGV) do
      option(:v, :verbose, :default => false, :switch => true)
      option(:applicable_age, :default => 10, :switch => 20)
    end

    # without `-v`
    s.value_for(:verbose) #=> false

    # using `-v`
    s.value_for(:verbose) #=> true

    # using `--applicable_age`
    s.value_for(:applicable_age) #=> 20

Callbacks
---------

If you'd like to trigger an event when an option is used, you can pass a
block to your option. Here's how:

    Slop.parse(ARGV) do
      opt(:v, :version, "Display the version") do
        puts "Version 1.0.1"
        exit
      end
    end

Now when using the `--version` option on the command line, the trigger will
be called and its contents executed.

Casting
-------

If you want to return values of specific types, for example a Symbol or Integer
you can pass the `:as` attribute to your option.

    s = Slop.parse("--age 20") do
      opt(:age, true, :as => Integer) # :int/:integer both also work
    end
    s.value_for(:age) #=> 20 # not "20"

Slop will also check your default attributes type to see if it can cast the new
value to the same type.

    s = Slop.parse("--port 110") do
      opt(port, true, :default => 80)
    end
    s.value_for(:port) #=> 110

Lists
-----

You can of course also parse lists into options. Here's how:

    s = Slop.parse("--people lee,injekt") do
      opt(:people, true, :as => Array)
    end
    s.value_for(:people) #=> ["lee", "injekt"]

You can also change both the split delimiter and limit

    s = Slop.parse("--people lee:injekt:bob") do
      opt(:people, true, :as => Array, :delimiter => ':', :limit => 2)
    end
    s.value_for(:people) #=> ["lee", "injekt:bob"]

Contributing
------------

If you'd like to contribute to Slop (it's **really** appreciated) please fork
the GitHub repository, create your feature/bugfix branch, add specs, and send
me a pull request. I'd be more than happy to look at it.
