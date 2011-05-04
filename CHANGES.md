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
• Add `:io` for using a custom IO object when using the `:help` option
* Numerous performance tweaks