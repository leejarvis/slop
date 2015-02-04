Changelog
=========

HEAD (unreleased)
-----------------

Features:
  * Support for FloatOption #156 (Rick Hull)
  * Support for `limit` config to ArrayOption.
  * Support for `tail` config to add options to the bottom of
    the help text.
  * Add explicit setter (#[]=) to Result class. #162
  * Implement flag gettings for UnknownOption and MissingArgument
    error classes. #165 (sigurdsvela)

Minor enhancements:
  * Reset parser every time `parse` is called.

Bug fixes:
  * Remove "--" from unprocessed arguments #157 (David Rodríguez).

v4.0.0 (2014-12-27)
-------------------

Features:
  * Rebuilt from the ground up. See the v3 changelog for all existing
    changes: https://github.com/leejarvis/slop/blob/v3/CHANGES.md
