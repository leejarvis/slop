task :test do
  $:.unshift './test'
  Dir.glob("test/*_test.rb").each { |test| require "./#{test}" }
end

task :default => :test
