require_relative 'lib/taoism/version'

Gem::Specification.new do |spec|
  spec.name     = 'taoism'
  spec.version  = Taoism::VERSION
  spec.licenses = ['BSD-1-Clause']
  spec.homepage = 'https://dub.sh/taoism'
  spec.summary  = 'A toy language inspired by Tao'
  spec.author   = 'oneureka'
  spec.email    = 'oneureka@github.io'
  spec.files    = Dir['lib/**/*']

  spec.executable = 'taoism'
  spec.add_dependency 'racc', '~> 1.8.1'
  spec.required_ruby_version = '>= 3.0'
end
