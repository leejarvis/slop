require 'rspec/core/rake_task'
require File.expand_path('../lib/slop', __FILE__)

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ["-c", "--fail-fast", "-f documentation"]
  spec.pattern = 'spec/**/*_spec.rb'
end

desc "Install Slop as a Ruby gem"
task :install do
  sh("gem build slop.gemspec")
  sh("gem install slop-#{Slop::VERSION}.gem")
end

task :default => :spec
