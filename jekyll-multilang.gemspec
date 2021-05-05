# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jekyll-multilang/version'

Gem::Specification.new do |s|
  s.name        = 'jekyll-multilang'
  s.version     = JekyllMultilang::VERSION
  s.authors     = ['Stefan Mertl']
  s.email       = ['info@mertl-research.at']
  s.homepage    = 'http://github.com/stefanmaar/jekyll-multilang'
  s.summary     = 'Jekyll extensions for multilanguage site.'
  s.licenses    = ['GPL 3.0']
  s.description = 'Support for multiple languages.'
  
  s.add_runtime_dependency('jekyll', '~> 4.0')

  s.files        = Dir['lib/**/*']
  s.require_paths = ['lib']
end
