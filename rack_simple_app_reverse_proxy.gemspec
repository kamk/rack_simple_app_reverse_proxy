# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack_simple_app_reverse_proxy/version'

Gem::Specification.new do |spec|
  spec.name          = "rack_simple_app_reverse_proxy"
  spec.version       = RackSimpleAppReverseProxy::VERSION
  spec.authors       = ["Kamil Kukura"]
  spec.email         = ["kamil.kukura@gmail.com"]
  spec.summary       = %q{Simple reverse proxy for embedding external application using Rack}
  spec.description   = %q{This proxy fetches remote app's page and makes its head and body accessible as two environment variables. It is useful for integration of remote app into the current project.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10"
  spec.add_dependency "rack", "~> 1"
  spec.add_dependency "nokogiri", "~> 1.6"
end
