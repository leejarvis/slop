task :test do
  $:.unshift './test'
  Dir.glob("test/*_test.rb").each { |test| require "./#{test}" }
end

task :test_all do
  sh "rvm rake test"
end

task :default => :test
