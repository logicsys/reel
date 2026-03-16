# -*- encoding: utf-8 -*-
require File.expand_path('../lib/reel/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Arcieri"]
  gem.email         = ["tony.arcieri@gmail.com"]
  gem.description   = "A Celluloid::IO-powered HTTP server"
  gem.summary       = "A Reel good HTTP server"
  gem.homepage      = "https://github.com/celluloid/reel"

  gem.executables   = Dir.glob("bin/*").map { |f| File.basename(f) }
  gem.files         = Dir.glob("{lib,bin,spec,examples,benchmarks}/**/*") + %w[
    reel.gemspec Gemfile Rakefile README.md CHANGES.md LICENSE.txt
  ]
  gem.test_files    = Dir.glob("{test,spec,features}/**/*")
  gem.name          = "reel"
  gem.require_paths = ["lib"]
  gem.version       = Reel::VERSION

  gem.required_ruby_version = '>= 3.3.0'

  gem.add_runtime_dependency 'celluloid',        '>= 0.15.1'
  gem.add_runtime_dependency 'celluloid-io',     '>= 0.15.0'
  gem.add_runtime_dependency 'celluloid-fsm',    '>= 0.20.0'
  gem.add_runtime_dependency 'http',             '>= 0.6.0'
  gem.add_runtime_dependency 'websocket-driver', '>= 0.5.1'

  gem.add_development_dependency 'rake', '>= 12.0'
  gem.add_development_dependency 'rspec', '>= 3.0'
  gem.add_development_dependency 'certificate_authority'
  gem.add_development_dependency 'websocket_parser', '>= 0.1.6'
end
