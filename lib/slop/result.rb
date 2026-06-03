# frozen-string-literal: true

module Slop
  # This class encapsulates a Parser and Options pair. The idea is that
  # the Options class shouldn't have to deal with what happens when options
  # are parsed, and the Parser shouldn't have to deal with the state of
  # options once parsing is complete. This keeps the API really simple; A
  # Parser parses, Options handles options, and this class handles the
  # result of those actions. This class contains the important most used
  # methods.
  class Result
    attr_reader :parser, :options

    def initialize(parser)
      @parser  = parser
      @options = parser.options
    end

    # Returns an option's value, nil if the option does not exist.
    def [](flag)
      (o = option(flag)) && (parser.opt_values.key?(o) ? parser.opt_values[o] : o.value)
    end
    alias get []

    # Returns an option's value, raises UnknownOption if the option does not exist.
    def fetch(flag)
      o = option(flag)
      if o.nil?
        cleaned_key = clean_key(flag)
        raise UnknownOption.new("option not found: '#{cleaned_key}'", "#{cleaned_key}")
      else
        parser.opt_values.key?(o) ? parser.opt_values[o] : o.value
      end
    end

    # Set the value for an option. Raises an ArgumentError if the option
    # does not exist.
    def []=(flag, value)
      if o = option(flag)
        o.value = value
        parser.opt_values[o] = value
      else
        raise ArgumentError, "no option with flag `#{flag}'"
      end
    end
    alias set []=

    # Returns an Option if it exists. Ignores any prefixed hyphens.
    def option(flag)
      options.find do |o|
        o.flags.any? { |f| clean_key(f) == clean_key(flag) }
      end
    end

    def method_missing(name, *args, &block)
      if respond_to_missing?(name)
        (o = option(name.to_s.chomp("?"))) && used_options.include?(o)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.end_with?("?") || super
    end

    # Returns an Array of Option instances that were used.
    def used_options = parser.used_options

    # Returns an Array of Option instances that were not used.
    def unused_options = parser.unused_options

    # Example:
    #
    #   opts = Slop.parse do |o|
    #     o.string '--host'
    #     o.int '-p'
    #   end
    #
    #   # ruby run.rb connect --host 123 helo
    #   opts.arguments #=> ["connect", "helo"]
    #
    # Returns an Array of String arguments that were not parsed.
    def arguments = parser.arguments
    alias args arguments

    # Returns a hash with option key => value.
    def to_hash
      @options.reject(&:null?).to_h { [_1.key, parser.opt_values[_1] || _1.value] }
    end
    alias to_h to_hash

    def to_s(**opts) = options.to_s(**opts)

    private

    def clean_key(key)
      Slop.normalize_flag(key, underscore: parser.config[:underscore_flags])
    end
  end
end
