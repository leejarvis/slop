require 'rspec/core/rake_task'
require File.join(File.dirname(__FILE__), 'lib/slop')

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["-c", "--fail-fast", "-f documentation"]
  spec.pattern = 'spec/**/*_spec.rb'
end

namespace :readme do

  desc "Modify readme documentation automatically"
  task :compile do
    latest_version  = 'slop-' + Slop::VERSION
    readme_filepath = File.join(File.dirname(__FILE__), "README.md")

    puts "Updating gem commands to instruct developer with version #{latest_version}"

    working_readme = File.read(readme_filepath)
    working_readme.gsub! /(slop-[0-9]+\.[0-9]+\.[0-9]+)/, latest_version

    File.open(readme_filepath, "w") { |readme| readme.puts working_readme }
  end

end

task :default => :spec
