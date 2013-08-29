class Slop
  class OptionBuilder
    class << self

      def build(command, args, &block)
        short       = extract_flag(args, /\A\-?([a-z])(=)?\z/)
        long        = extract_flag(args, /\A\-?-?([a-zA-Z][a-zA-Z_-]+)(=)?\z/)
        description = extract_description(args)
        config      = extract_config(args)

        # default config options extracted from flags
        config[:argument] = @argument

        Option.new(command, short, long, description, config, &block)
      end

      private

      def extract_flag(args, regex)
        if args[0] =~ regex
          args.shift
          @argument = $2 == '='
          $1
        end
      end

      def extract_description(args)
        if args[0].respond_to?(:to_str)
          args.shift.to_str
        end
      end

      def extract_config(args)
        args.shift || {}
      end

    end
  end
end
