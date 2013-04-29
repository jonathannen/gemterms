Gem::Specification.new do |s|
  s.name        = 'gemterms'
  s.version     = '0.1.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Jon Williams']
  s.email       = ['jon@jonathannen.com']
  s.homepage    = 'https://github.com/jonathannen/gemterms'
  s.summary     = 'Checks the licensing of your Gemfile.'
  s.description = 'Scans Gemfiles to see what licenses are in use.'

  s.license = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'bundler', '>= 1.0.10'
end
