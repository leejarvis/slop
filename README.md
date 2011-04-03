Slop
====

Slop is a simple option collector with an easy to remember syntax and friendly API.

Installation
------------

### Rubygems

    gem install slop

### GitHub

    git clone git://github.com/injekt/slop.git
    gem build slop.gemspec
    gem install slop-<version>.gem

Usage
-----
	# parse assumes ARGV, otherwise you can pass it your own Array
	opts = Slop.parse do
	  on :v, :verbose, 'Enable verbose mode' 	   # boolean value
	  on :n, :name, 'Your name', true              # compulsory argument
	  on :s, :sex, 'Your sex', :optional => false  # the same thing
	  on :a, :age, 'Your age', :optional => true   # optional argument
	end

	# if ARGV is `-v --name 'lee jarvis' -s male`
	opts.verbose? #=> true
	opts.name?    #=> true
	opts[:name]   #=> 'lee jarvis'
	opts.age?     #=> false
	opts[:age]    #=> nil

You can also return your options as a Hash

	opts.to_hash #=> {'name' => 'Lee Jarvis', 'verbose' => true, 'age' => nil, 'sex' => 'male'}

	# Symbols
	opts.to_hash(true) #=> {:name => 'Lee Jarvis', :verbose => true, :age => nil, :sex => 'male'}

If you don't like the method `on` (because it sounds like the option **expects**
a block), you can use the `opt` or `option` alternatives.

	on :v, :verbose
	opt :v, :verbose
	option :v, :verbose

If you don't like that Slop evaluates your block, or you want slop access
inside of your block without referring to `self`, you can pass a block argument to
`parse`.

	Slop.parse do |opts|
	  opts.on :v, :verbose
	  opts.on :n, :name, 'Your name', true
	end

If you want some pretty output for the user to see your options, you can just
send the Slop object to `puts` or use the `help` method.

	puts opts
	puts opts.help

Will output something like

    -v, --verbose      Enable verbose mode
    -n, --name         Your name
    -a, --age          Your age

You can also add a banner using the `banner` method

	opts = Slop.parse
	opts.banner = "Usage: foo.rb [options]"

or

	opts = Slop.parse do
	  banner "Usage: foo.rb [options]"
	end

Helpful Help
------------

Long form:

    Slop.parse do
      ...
      on :h, :help, 'Print this help message', :tail => true do
        puts help
        exit
      end
    end

Shortcut:

    Slop.parse :help => true do
      ...
    end

Parsing
-------

Slop's pretty good at parsing, let's take a look at what it'll extract for you

    Slop.parse do
      on 's', 'server', true
      on 'p', 'port', true, :as => :integer
      on 'username', true, :matches => /[^a-zA-Z]+$/
      on 'password', true
    end

Now throw some options at it:

    -s ftp://foobar.com -p1234 --username=FooBar --password 'hello there'

Here's what we'll get back

	{
		:server=>"ftp://foobar.com",
		:port=>1234,
		:username=>"FooBar",
		:password=>"hello there"
	}

Callbacks
---------

If you'd like to trigger an event when an option is used, you can pass a
block to your option. Here's how:

    Slop.parse do
      on :V, :version, 'Print the version' do
        puts 'Version 1.0.0'
        exit
      end
    end

Now when using the `--version` option on the command line, the trigger will
be called and its contents executed.

Yielding Non Options
--------------------

If you pass a block to `Slop#parse`, Slop will yield non-options as
they're found, just like
[OptionParser](http://rubydoc.info/stdlib/optparse/1.9.2/OptionParser:order)
does it.

	opts = Slop.new do
	  on :n, :name, :optional => false
	end

	opts.parse do |arg|
	  puts arg
	end

	# if ARGV is `foo --name Lee bar`
	foo
	bar

Negative Options
----------------

Slop also allows you to prefix `--no-` to an option which will force the option
to return a false value.

	opts = Slop.parse do
		on :v, :verbose, :default => true
	end

	# with no command line options
	opts[:verbose] #=> true

	# with `--no-verbose`
	opts[:verbose] #=> false
	opts.verbose?  #=> false

Short Switches
--------------

Want to enable multiple switches at once like rsync does? By default Slop will
parse `-abcd` as the option `a` with the argument `bcd`, this can be disabled
by passing the `:multiple_switches` option to a new Slop object.

    opts = Slop.new(:strict, :multiple_switches) do
      on :a, 'First switch'
      on :b, 'Second switch'
      on :c, 'Third switch'
    end

    opts.parse

    # Using `-ac`
    opts[:a] #=> true
    opts[:b] #=> false
    opts[:c] #=> true

Ugh, Symbols
------------

Fine, don't use them

	Slop.parse do
	  on :n, :name, 'Your name'
	  on 'n', 'name', 'Your name'
	  on '-n', '--name', 'Your name'
	end

All of these options will do the same thing

Ugh, Blocks
-----------

C'mon man, this is Ruby, GTFO if you don't like blocks.

	opts = Slop.new
	opts.on :v, :verbose
	opts.parse

Smart
-----

Slop is pretty smart when it comes to building your options, for example if you
want your option to have a flag attribute, but no `--option` attribute, you
can do this:

	on :n, "Your name"

and Slop will detect a description in place of an option, so you don't have to
do this:

	on :n, nil, "Your name", true

You can also try other variations:

	on :name, "Your name"
	on :n, :name
	on :name, true

Lists
-----

You can of course also parse lists into options. Here's how:

	opts = Slop.parse do
	  opt :people, true, :as => Array
	end

	# ARGV is `--people lee,john,bill`
	opts[:people] #=> ['lee', 'john', 'bill']

You can also change both the split delimiter and limit

    opts = Slop.parse do
      opt :people, true, :as => Array, :delimiter => ':', :limit => 2)
    end

    # ARGV is `--people lee:injekt:bob`
    opts[:people] #=> ["lee", "injekt:bob"]

Strict Mode
-----------

Passing `strict => true` to `Slop.parse` causes it to raise a `Slop::InvalidOptionError`
when an invalid option is found (`false` by default):

    Slop.new(:strict => true).parse(%w/--foo/)
    # => Slop::InvalidOptionError: Unknown option -- 'foo'

and it handles multiple invalid options with a sprinkling of pluralization:

    Slop.new(:strict => true).parse(%w/--foo --bar -z/)
    # => Slop::InvalidOptionError: Unknown options -- 'foo', 'bar', 'z'

Significantly, however, Slop will still parse the valid options:

    slop = Slop.new(:strict => true, :help => true) do
      banner "Usage:\n\t./awesome_sauce [options]\n\nOptions:"
      on :n, :name, 'Your name'
    end

    begin
      slop.parse(%w/--foo --bar -z/)
    rescue Slop::InvalidOptionError => e
      puts "\n#{e.message}\n\n"
      puts slop
      exit
    end

yields:

    Unknown options -- 'foo', 'bar', 'z'

    Usage:
    	./awesome_sauce [options]

    Options:
        -n, --name      Your name
        -h, --help      Print this help message

Woah woah, why you hating on OptionParser?
------------------------------------------

I'm not, honestly! I love OptionParser. I really do, it's a fantastic library.
So why did I build Slop? Well, I find myself using OptionParser to simply
gather a bunch of key/value options, usually you would do something like this:

	require 'optparse'

	things = {}

	opt = OptionParser.new do |opt|
	  opt.on('-n', '--name NAME', 'Your name') do |name|
	    things[:name] = name
	  end

	  opt.on('-a', '--age AGE', 'Your age') do |age|
		things[:age] = age
	  end

	  # you get the point
	end

	opt.parse
	# do something with things

Which is all great and stuff, but it can lead to some repetition, the same
thing in Slop:

	require 'slop'

	opts = Slop.parse do
	  on :n, :name, 'Your name', true
	  on :a, :age, 'Your age', true
	end

	things = opts.to_hash