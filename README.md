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
