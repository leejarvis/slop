require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["-c", "--fail-fast", "-f documentation"]
  spec.pattern = 'spec/**/*_spec.rb'
end

task :default => :spec