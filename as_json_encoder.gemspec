# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'as_json_encoder/version'

Gem::Specification.new do |spec|
  spec.name          = "as_json_encoder"
  spec.version       = AsJsonEncoder::VERSION
  spec.authors       = ["Godfrey Chan"]
  spec.email         = ["godfreykfc@gmail.com"]
  spec.summary       = "A JSON encoder that is tailored to the needs of Rails."
  spec.homepage      = "https://github.com/chancancode/as_json_encoder"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 4.1"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
