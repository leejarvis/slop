Slop
====

Slop is a simple option parser with an easy to remember syntax and friendly API.

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
end

ARGV #=> -v --host 192.168.0.1

opts[:host]   #=> 192.168.0.1
opts.verbose? #=> true
opts.quiet?   #=> false

opts.to_hash  #=> { host: "192.168.0.1", port: 80, verbose: true, quiet: false }
```

Advanced Usage
--------------

Printing Help
-------------

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
`StringOption`. When you type `o.array` Slop looks for an option called
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
