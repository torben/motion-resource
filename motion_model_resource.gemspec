# -*- encoding: utf-8 -*-
Version = "0.1.7"

Gem::Specification.new do |gem|

  # Gem information
  gem.name          = 'motion_model_resource'
  gem.version       = Version
  gem.description   = 'Simple JSON API Wrapper for MotionModel on RubyMotion'
  gem.summary       = 'Simple JSON API Wrapper for MotionModel on RubyMotion'
  gem.homepage      = 'https://github.com/torben/motion-resource'

  # Gem credentials
  gem.authors       = ['Torben Toepper', 'Stefan Vermaas']
  gem.email         = ['lshadyl@googlemail.com', 'stefan@yellowduckwebdesign.nl']

  # Gem file actions
  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  gem.files         = files
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # Gem dependencies
  gem.add_dependency 'motion_model', '~> 0.4.4'
  gem.add_dependency 'bubble-wrap', '~> 1.3.0'
  gem.add_dependency 'motion-support', '~> 0.1.0'
  gem.add_dependency 'webstub', '~> 0.3.0'
end
