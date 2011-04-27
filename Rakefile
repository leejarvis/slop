task :test do
  $LOAD_PATH.unshift './test'
  Dir.glob("test/*_test.rb").each { |test| require "./#{test}" }
end

task :default => :test