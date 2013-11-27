# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'brer_rabbit/version'

Gem::Specification.new do |spec|
  spec.name          = "brer_rabbit"
  spec.version       = BrerRabbit::VERSION
  spec.authors       = ["C. Jason Harrelson"]
  spec.email         = ["jason@lookforwardenterprises.com"]
  spec.description   = %q{A work queue built on RabbitMQ.  See README for more details.}
  spec.summary       = %q{A work queue built on RabbitMQ.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = ['rabbit-wq'] #spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "bunny", "~> 1"
  spec.add_dependency "celluloid", "~> 0"
  spec.add_dependency "trollop", "~> 2"
  spec.add_dependency "yell", "~> 1"

end
