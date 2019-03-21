
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'angular_commit_lint/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'danger-angular_commit_lint'
  spec.version       = AngularCommitLint::VERSION
  spec.authors       = ['Jon Allured', 'Simeon Cheeseman']
  spec.email         = ['jon.allured@gmail.com']
  spec.description   = 'A Danger Plugin that ensures nice and tidy commit messages.'
  spec.summary       = "A Danger Plugin that ensure commit messages follow the angular commit pattern, are not too long, don't end in a period and have a line between subject and body"
  spec.homepage      = 'https://github.com/simeonc/danger-angular_commit_lint'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'danger-plugin-api', '~> 1.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'yard'
end
