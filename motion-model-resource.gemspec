# -*- encoding: utf-8 -*-
require File.expand_path('../lib/motion-model-resource/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Torben Toepper"]
  gem.email         = ["message@torbentoepper.de"]
  gem.description   = "Simple JSON API Wrapper for MotionModel on RubyMotion"
  gem.summary       = "Simple JSON API Wrapper for MotionModel on RubyMotion"
  gem.homepage      = "https://github.com/torben/motion-resource"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "motion-model-resource"
  gem.require_paths = ["lib"]
  gem.add_dependency 'bubble-wrap', '>= 1.3.0'
  gem.add_dependency 'motion-support', '>=0.1.0'
  gem.add_dependency 'motion_model', '>=0.4.4'
  gem.add_dependency 'webstub', '>=0.3.0'
  gem.version       = MotionModelResource::VERSION
end
