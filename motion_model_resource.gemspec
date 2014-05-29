# -*- encoding: utf-8 -*-
require File.expand_path('../lib/motion-model-resource/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Torben Toepper"]
  gem.email         = ["message@torbentoepper.de"]
  gem.description   = "Simple REST JSON API Wrapper for MotionModel on RubyMotion"
  gem.summary       = "Simple REST JSON API Wrapper for MotionModel on RubyMotion"
  gem.homepage      = "https://github.com/torben/motion-resource"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "motion_model_resource"
  gem.require_paths = ["lib"]
  gem.version       = MotionModelResource::VERSION
  gem.licenses      = ["MIT"]

  if gem.respond_to? :specification_version
    gem.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      gem.add_runtime_dependency(%q<bubble-wrap>, [">= 1.3.0"])
      gem.add_runtime_dependency(%q<motion-support>, [">= 0.1.0"])
      gem.add_runtime_dependency(%q<motion_model>, [">= 0.4.4"])
      gem.add_runtime_dependency(%q<webstub>, ['>= 0.3.0'])
    else
      gem.add_dependency(%q<bubble-wrap>, [">= 1.3.0"])
      gem.add_dependency(%q<motion-support>, [">= 0.1.0"])
      gem.add_dependency(%q<motion_model>, [">= 0.4.4"])
      gem.add_dependency(%q<webstub>, ['>= 0.3.0'])
    end
  else
    gem.add_dependency(%q<bubble-wrap>, [">= 1.3.0"])
    gem.add_dependency(%q<motion-support>, [">= 0.1.0"])
    gem.add_dependency(%q<motion_model>, [">= 0.4.4"])
    gem.add_dependency(%q<webstub>, ['>= 0.3.0'])
  end
end
