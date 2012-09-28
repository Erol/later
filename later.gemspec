# -*- encoding: utf-8 -*-
require File.expand_path('../lib/later/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Erol Fornoles']
  gem.email         = ['erol.fornoles@gmail.com']
  gem.description   = %q{Later is a Redis-backed event scheduling library for Ruby}
  gem.summary       = %q{Later is a Redis-backed event scheduling library for Ruby}
  gem.homepage      = 'http://erol.github.com/later'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'later'
  gem.require_paths = ['lib']
  gem.version       = Later::VERSION

  gem.add_dependency 'redis'
  gem.add_dependency 'nest'
  gem.add_dependency 'json'
  gem.add_dependency 'predicates'

  gem.add_development_dependency 'minitest'
end
