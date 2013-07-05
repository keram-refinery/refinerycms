# Encoding: UTF-8

version = Refinery::Version.to_s

Gem::Specification.new do |s|
  s.platform          = Gem::Platform::RUBY
  s.name              = 'refinerycms-<%= plural_name %>'
  s.version           = '1.0'
  s.description       = 'Ruby on Rails <%= plural_name.titleize %> forms-extension for Refinery CMS'
  s.date              = '<%= Time.now.strftime('%Y-%m-%d') %>'
  s.summary           = '<%= plural_name.titleize %> forms-extension for Refinery CMS'
  s.require_paths     = %w(lib)
  s.files             = Dir["{app,config,db,lib}/**/*"] + ["readme.md"]

  # Runtime dependencies
  s.add_dependency    'refinerycms-core',     '~> <%%= version %>'
  s.add_dependency    'refinerycms-settings', '~> <%%= version %>'
end
