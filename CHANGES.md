TBA
---

* Feature: Autocreate (auto create options at parse time, making assumptions)

1.6.1 (2011-06-01)
------------------

* Fix tests and using a temporary Array for ARGV, fixes RubyGems Test issues
* General cleanup of code

1.6.0 (2011-05-18)
------------------

* Add `:ignore_case` to Slop options for case insensitive option matching
* Add `:on_noopts` for triggering an event when the arguments contain no
  options
* Add `:unless` to Slop::Option for omitting execution of the Options block
  when this object exists in the Array of items passed to Slop.new
* Bugfix: Do not parse negative integers as options. A valid option must
  start with an alphabet character
* Bugfix: Allow a Range to accept a negative Integer at either end

1.5.5 (2011-05-03)
------------------

* Bugfix: only attempt to extract options prefixed with `-`

1.5.4 (2011-05-01)
------------------

* Bugfix: `parse!` should not remove items with the same value as items used
  in option arguments. Fixes #22 (Utkarsh Kukreti)

1.5.3 (2011-04-22)
------------------

* Bugfix: Use integers when fetching array indexes, not strings

1.5.2 (2011-04-17)
------------------

* Bugfix: Ensure `ARGV` is empty when using the `on_empty` event

1.5.0 (2011-04-15)
------------------

* Add `Slop#get` as alias to `Slop#[]`
* Add `Slop#present?` as alias for `Slop#<option>?`
* Add `Option#count` for monitoring how many times an option is called
* Add `:io` for using a custom IO object when using the `:help` option
* Numerous performance tweaks