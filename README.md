Slop
====

Slop is a simple option parser with an easy to remember syntax and friendly API.

This README is targeted at Slop v3.

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

```ruby
# parse assumes ARGV, otherwise you can pass it your own Array
opts = Slop.parse do
  banner "ruby foo.rb [options]\n"
  on :name=, 'Your name'
  on :p, :password, 'Your password', :argument => :optional
  on :v :verbose, 'Enable verbose mode'
end

# if ARGV is `--name Lee -v`
opts.verbose?  #=> true
opts.password? #=> false
opts[:name]    #=> 'lee'
```

Slop supports several methods of writing options:

```ruby
# These options all do the same thing
on '-n', '--name', 'Your name', :argument => true
on 'n', :name=, 'Your name'
on :n, '--name=', 'Your name'

# As do these
on 'p', '--password', 'Your password', :argument => :optional
on :p, :password, 'Your password', :optional_argument => true
on '-p', 'password=?', 'Your password'
```

You can also return your options as a Hash:

```ruby
opts.to_hash #=> { :name => 'lee', :verbose => nil, :password => nil }
```

Printing Help
-------------

Slop attempts to build a good looking help string to print to your users. You
can see this by calling `opts.help` or simply `puts opts`.

Configuration Options
---------------------

All of these options can be sent to `Slop.new` or `Slop.parse` in Hash form.

* `strict` - Enable strict mode. When processing unknown options, Slop will
  raise an `InvalidOptionError`. **default:** *false*.
* `help` - Automatically add the `--help` option. **default:** *false*.
* `banner` - Set this options banner text. **default:** *nil*.
* `ignore_case` - When enabled, `-A` will look for the `-a` option if `-A`
  does not exist. **default:** *false*.
* `autocreate` - Autocreate options on the fly. **default:** *false*.
* `arguments` - Force all options to expect arguments. **default:** *false*.
* `optional_arguments` - Force all options to accept optional arguments.
  **default:** *false*.
* `multiple_switches` - When disabled, Slop will parse `-abc` as the option `a`
   with the argument `bc` rather than 3 separate options. **default:** *true*.
* `longest_flag` - The longest string flag, used to aid configuring help
   text. **default:** *0*.

Features
--------

Check out the following wiki pages for more features:

* [Ranges](https://github.com/injekt/slop/wiki/Ranges)
* [Auto Create](https://github.com/injekt/slop/wiki/Auto-Create)

Woah woah, why you hating on OptionParser?
------------------------------------------

I'm not, honestly! I love OptionParser. I really do, it's a fantastic library.
So why did I build Slop? Well, I find myself using OptionParser to simply
gather a bunch of key/value options, usually you would do something like this:

```ruby
require 'optparse'

things = {}

opt = OptionParser.new do |opt|
  opt.on('-n', '--name NAME', 'Your name') do |name|
    things[:name] = name
  end

  opt.on('-a', '--age AGE', 'Your age') do |age|
    things[:age] = age.to_i
  end

  # you get the point
end

opt.parse
things #=> { :name => 'lee', :age => 105 }
```

Which is all great and stuff, but it can lead to some repetition. The same
thing in Slop:

```ruby
require 'slop'

opts = Slop.parse do
  on :n, :name=, 'Your name'
  on :a, :age=, 'Your age', :as => :int
end

opts.to_hash #=> { :name => 'lee', :age => 105 }
```