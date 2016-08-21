Changelog
=========

v4.4.1 (2016-08-21)
-------------------

Bug fixes:
  * Handle bad constant names in `Slop.option_defined?`. #198
    (Ellen Marie Dash)

v4.4.0 (2016-08-15)
-------------------

Features
  * Support parsing arguments prefixed with dashes. #192 (Andrew Clemons)

Bug fixes:
  * Retain sort order inside tail sort. #193 (Caio Chassot)

v4.3.0 (2016-03-19)
-------------------

Features
  * Allow disabling array delimiter. #189 (Mike Pastore)
  * Allow passing custom banner as config. #191 (Philip Rees)

v4.2.1 (2015-11-25)
-------------------

Features:
  * Better handling of option names with multiple words. #169 (Tim Rogers)

Minor enhancements:
  * add ARGF notes to Arguments (README). #173 (Rick Hull)

Bug fixes:
  * Fix arguments removed with option arguments. #182 (Naoki Mizuno)
  * Fix bug where true is passed to BoolOption block regardless
    of --no- prefix. #184 (Ben Brady)
  * only raise MissingArgument if not `default_value`. #163 (Ben Brady)

v4.2.0 (2015-04-18)
-------------------

Features:
  * Support for Regexp option type #167 (Laurent Arnoud)
  * Support prefixed `--no-` for explicitly setting boolean options
    to `false` #168
  * Better handling of flags with multiple words #169 (Tim Rogers)

v4.1.0 (2015-04-18)
-------------------

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
