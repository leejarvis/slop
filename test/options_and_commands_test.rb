require 'helper'

class OptionsAndCommandsTest < TestCase

  test "allows options before and after commands" do
    command_line = %w'-application slop add -m TheMessage'

    opts = Slop.parse! command_line, :strict => true do
      on :a, :application=

      command :add do
        on :m, :message=
      end
    end

    assert_equal "slop", opts[:application]
    assert_equal "TheMessage", opts.fetch_command(:add)[:message]
  end


end
