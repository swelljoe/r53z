# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'r53z/version'

Gem::Specification.new do |spec|
  spec.name          = "r53z"
  spec.license="gplv3"
  spec.version       = R53z::VERSION
  spec.authors       = ["Joe Cooper"]
  spec.email         = ["swelljoe@gmail.com"]

  spec.summary       = %q{Simple zone manager for Route 53.}
  spec.homepage      = "http://github.com/swelljoe/r53z"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = "r53z" 
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.1.0'
  spec.add_development_dependency "bundler", ">= 1.12"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency('rdoc')
  spec.add_dependency('methadone', '~> 1.9.2')
  spec.add_dependency('aws-sdk')
  spec.add_dependency('inifile')
  spec.add_development_dependency('pry')
  spec.add_development_dependency('test-unit')
end
