Gem::Specification.new do |s|
  s.name = 'slop'
  s.version = '0.1.7'
  s.summary = 'Option gathering made easy'
  s.description = ''
  s.author = 'Lee Jarvis'
  s.email = 'lee@jarvis.co'
  s.homepage = 'http://rubydoc.info/github/injekt/slop'
  s.required_ruby_version = '>= 1.9.1'
  s.files = ['LICENSE', 'README.md', 'lib/slop.rb',
    'lib/slop/option.rb', 'spec/slop_spec.rb', 'spec/option_spec.rb']

  s.add_development_dependency('rspec', '= 2.1.0')
end
