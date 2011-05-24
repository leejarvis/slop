task :test do
  $:.unshift './test'
  Dir.glob("test/*_test.rb").each { |test| require "./#{test}" }
end

task :test_all do
  sh "rvm 1.8.7,ruby,rbx,1.9.2 exec rake test"
end

task :default => :test