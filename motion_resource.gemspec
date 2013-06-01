# -*- encoding: utf-8 -*-
require File.expand_path('../motion/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Torben Toepper"]
  gem.email         = ["lshadyl@googlemail.com"]
  gem.description   = "Simple API Wrapper for MotionModel on RubyMotion"
  gem.summary       = "Simple API Wrapper for MotionModel on RubyMotion"
  gem.homepage      = "https://github.com/torben/MotionResource"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "motion-resource"
  gem.require_paths = ["lib"]
  gem.add_dependency 'bubble-wrap', '1.3.0.osx'
  gem.add_dependency 'motion-support', '>=0.1.0'
  gem.add_dependency 'motion_model', '>=0.4.4'
  gem.version       = MotionResource::VERSION
end
