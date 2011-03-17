task :test do
  $LOAD_PATH.unshift './lib'
  require 'slop'
  require 'minitest/autorun'
  begin; require 'turn'; rescue LoadError; end
  Dir.glob("test/**/*_test.rb").each { |test| require "./#{test}" }
end

task :default => :test