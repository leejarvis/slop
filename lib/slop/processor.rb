class Slop
  class Processor

    def self.process(command, items)
      Processor.new(command, items).process
    end

    attr_reader :command, :items, :trashed_indexes, :current_index

    def initialize(command, items)
      @command         = command
      @items           = items
      @trashed_indexes = []
      @current_index   = 0
    end

    def process
      items.each do |item|
        break if run_command(item)

        if flag_match?(item)
          option = command.options[item]
          if option
            process_option(option, item)
          else
            if command.config[:multiple_switches]
              process_multiple_switches(item)
            end
          end
        end
        @current_index += 1
      end

      # Remove trashed items
      @items.delete_if.with_index { |_, i| @trashed_indexes.include?(i) }
    end

    def process_option(option, item)
      if option.argument? || option.optional_argument?
        assign_argument(option)
      end

      option.execute
    end

    private

    def process_multiple_switches(item)
      command.clean_flag(item).split('').each do |flag|
        option = command.options[flag]
        process_option(option, flag) if option
      end
    end

    def argument
      items[current_index + 1]
    end

    def assign_argument(option)
      if option.argument?
        assign_compulsory_argument(option)
      elsif option.optional_argument?
        assign_optional_argument(option)
      end
    end

    def assign_compulsory_argument(option)
      if !argument || flag_match?(argument)
        raise MissingArgument.new(command, "`#{option.key}' expects an argument")
      else
        option.value = argument
        trash_argument
      end
    end

    def assign_optional_argument(option)
      unless flag_match?(argument)
        option.value = argument
        trash_argument
      end
    end

    def flag_match?(flag)
      command.flag_match?(flag)
    end

    def trash_item
      trashed_indexes << @current_index
    end

    def trash_argument
      trashed_indexes << @current_index + 1
    end

    def run_command(item)
      c = command.commands[item]
      c && c.parse(items[1..-1])
    end

  end
end
