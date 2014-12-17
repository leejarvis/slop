Slop
====

Slop is a simple option parser with an easy to remember syntax and friendly API.

Version 4 of Slop is aimed at Ruby 2.0 or later. Please use
[Version 3](https://github.com/leejarvis/slop/tree/v3) for Ruby 1.9 support.

[![Build Status](https://travis-ci.org/leejarvis/slop.png?branch=master)](http://travis-ci.org/leejarvis/slop)

Installation
------------

    gem install slop

Usage
-----

```ruby
opts = Slop.parse do |o|
  o.string '-h', '--host', 'a hostname'
  o.integer '--port', 'custom port', default: 80
  o.bool '-v', '--verbose', 'enable verbose mode'
  o.bool '-q', '--quiet', 'surpress output (quiet mode)'
  o.on '--version', 'print the version' do
    puts Slop::VERSION
    exit
  end
end

ARGV #=> -v --host 192.168.0.1

opts[:host]   #=> 192.168.0.1
opts.verbose? #=> true
opts.quiet?   #=> false

opts.to_hash  #=> { host: "192.168.0.1", port: 80, verbose: true, quiet: false }
```

Option types
------------

Built in Option types are as follows:

```ruby
o.string  #=> Slop::StringOption, expects an argument
o.bool    #=> Slop::BoolOption, no argument, aliased to BooleanOption
o.integer #=> Slop::IntegerOption, expects an argument, aliased to IntOption
o.array   #=> Slop::ArrayOption, expects an argument
o.null    #=> Slop::NullOption, no argument and ignored from `to_hash`
o.on      #=> alias for o.null
```

You can see all built in types in `slop/types.rb`. Suggestions or pull requests
for more types are welcome.

Advanced Usage
--------------

This example is really just to describe how the underlying API works.
It's not necessarily the best way to do it.

```ruby
opts = Slop::Options.new
opts.banner = "usage: connect [options] ..."
opts.separator ""
opts.separator "Connection options:"
opts.string "-H", "--hostname", "a hostname"
opts.int "-p", "--port", "a port", default: 80
opts.separator ""
opts.separator "Extra options:"
opts.array "--files", "a list of files to import"
opts.bool "-v", "--verbose", "enable verbose mode"

parser = Slop::Parser.new(opts)
result = parser.parse(["--hostname", "192.168.0.1"])

result.to_hash #=> { hostname: "192.168.0.1", port: 80,
                 #     files: [], verbose: false }

puts opts # prints out help
```

Arrays
------

Slop has a built in `ArrayOption` for handling array values:

```ruby
opts = Slop.parse do |o|
  # the delimiter defaults to ','
  o.array '--files', 'a list of files', delimiter: ','
end

# both of these will return o[:files] as ["foo.txt", "bar.rb"]:
# --files foo.txt,bar.rb
# --files foo.txt --files bar.rb
```

Custom option types
-------------------

Slop uses option type classes for every new option added. They default to the
`NullOption`. When you type `o.array` Slop looks for an option called
`Slop::ArrayOption`. This class must contain at least 1 method, `call`. This
method is executed at parse time, and the return value of this method is
used for the option value. We can use this to build custom option types:

```ruby
module Slop
  class PathOption < Option
    def call(value)
      Pathname.new(value)
    end
  end
end

opts = Slop.parse %w(--path ~/) do |o|
  o.path '--path', 'a custom path name'
end

p opts[:path] #=> #<Pathname:~/>
```

Custom options can also implement a `finish` method. This method by default
does nothing, but it's executed once *all* options have been parsed. This
allows us to go back and mutate state without having to rely on options
being parsed in a particular order. Here's an example:

```ruby
module Slop
  class FilesOption < ArrayOption
    def finish(opts)
      if opts.expand?
        self.value = value.map { |f| File.expand_path(f) }
      end
    end
  end
end

opts = Slop.parse %w(--files foo.txt,bar.rb -e) do |o|
  o.files '--files', 'an array of files'
  o.bool '-e', '--expand', 'if used, list of files will be expanded'
end

p opts[:files] #=> ["/full/path/foo.txt", "/full/path/bar.rb"]
```

Errors
------

Slop will raise errors for the following:

* An option used without an argument when it expects one: `Slop::MissingArgument`
* An option used that Slop doesn't know about: `Slop::UnknownOption`

These errors inherit from `Slop::Error`, so you can rescue them all.
Alternatively you can suppress these errors with the `suppress_errors` config
option:

```ruby
opts = Slop.parse suppress_errors: true do
  o.string '-name'
end

# or per option:

opts = Slop.parse do
  o.string '-host', suppress_errors: true
  o.int '-port'
end
```
