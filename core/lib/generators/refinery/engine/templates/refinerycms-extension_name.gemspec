# Encoding: UTF-8
require 'date'
require File.expand_path('../lib/refinery/<%= extension_name %>/version', __FILE__)

Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-<%= extension_name %>'
  s.version           = '0.0.1'
  s.description       = 'Ruby on Rails <%= extension_name.titleize %> extension for Refinery CMS'
  s.date              = Date.today.strftime("%Y-%m-%d")
  s.summary           = '<%= extension_name.titleize %> extension for Refinery CMS'
  s.authors           = ['FIX ME']
  s.email             = 'FIX ME'
  s.homepage          = 'FIX ME'
  s.require_paths     = %w(lib)
  s.files             = Dir["{app,config,db,lib}/**/*"] + ["readme.md"]

  # Runtime dependencies
  s.add_dependency             'refinerycms-core',    '~> <%= Refinery::Version.to_s %>'

  # Development dependencies (usually used for testing)
  s.add_development_dependency 'refinerycms-testing', '~> <%= Refinery::Version.to_s %>'
end
