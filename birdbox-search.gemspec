# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'birdbox-search/version'

Gem::Specification.new do |gem|
  gem.name          = "birdbox-search"
  gem.version       = Birdbox::Search::VERSION
  gem.authors       = ["Matthias Eder"]
  gem.email         = ["meder@birdbox.com"]
  gem.description   = %q{An abstraction of the ElasticSearch API powering Birdbox Search.}
  gem.summary       = %q{An abstraction of the ElasticSearch API powering Birdbox Search.}
  gem.homepage      = "http://www.birdbox.com"

  gem.add_dependency "rake", "~> 10.0.0"
  gem.add_dependency "tire", "~> 0.5.4"

  gem.add_development_dependency "yard", "~> 0.8.3"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
