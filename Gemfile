source 'https://rubygems.org'

gemspec

# Add i18n support.
gem 'refinerycms-i18n', '~> 2.718.0.dev', github: 'keram-refinery/refinerycms-i18n', :branch => 'refinery_light'
gem 'refinerycms-clientside', '~> 0.0.1', github: 'keram-refinery/refinerycms-clientside', branch: 'master'

# Links dialog
gem 'refinerycms-links', '~> 0.0.1', github: 'keram/refinerycms-links', branch: 'master'

gem 'quiet_assets', :group => :development

# Database Configuration
unless ENV['TRAVIS']
  gem 'activerecord-jdbcsqlite3-adapter', :platform => :jruby
  gem 'sqlite3', :platform => :ruby
end

if !ENV['TRAVIS'] || ENV['DB'] == 'mysql'
  group :mysql do
    gem 'activerecord-jdbcmysql-adapter', '>= 1.3.0.rc1', :platform => :jruby
    gem 'mysql2', :platform => :ruby
  end
end

if !ENV['TRAVIS'] || ENV['DB'] == 'postgresql'
  group :postgres, :postgresql do
    gem 'activerecord-jdbcpostgresql-adapter', '>= 1.3.0.rc1', :platform => :jruby
    gem 'pg', :platform => :ruby
  end
end

gem 'jruby-openssl', :platform => :jruby

group :test do
  gem 'refinerycms-testing', '~> 2.718.0.dev'
  gem 'generator_spec', '~> 0.9.2'
  gem 'launchy'
end


# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails', '>= 4.0.5'
gem 'uglifier'

gem 'turbolinks', '~> 2.2'

gem 'jquery-rails', '>= 3.1.0'

gem 'will_paginate', '~> 3.1'
gem 'i18n-iso639matrix', '~> 0.0.1', github: 'keram/i18n-iso639matrix', branch: 'master'

# Lock rake in order to prevent
# undefined method `last_comment' exception
gem 'rake', '< 11.0'
gem 'globalize', github: 'globalize/globalize', branch: '4-0-stable'

# Load local gems according to Refinery developer preference.
if File.exist? local_gemfile = File.expand_path('../.gemfile', __FILE__)
  eval File.read(local_gemfile)
end
