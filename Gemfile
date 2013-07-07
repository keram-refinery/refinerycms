source 'https://rubygems.org'

gemspec

# Add i18n support.
gem 'refinerycms-i18n', '~> 3.0.0.dev', :git => 'git://github.com/keram-refinery/refinerycms-i18n.git', :branch => 'refinery_light'

gem 'quiet_assets', :group => :development

# Database Configuration
unless ENV['TRAVIS']
  gem 'activerecord-jdbcsqlite3-adapter', :platform => :jruby
  gem 'sqlite3', :platform => :ruby
end

if !ENV['TRAVIS'] || ENV['DB'] == 'mysql'
  gem 'activerecord-jdbcmysql-adapter', :platform => :jruby
  gem 'jdbc-mysql', '= 5.1.13', :platform => :jruby
  gem 'mysql2', :platform => :ruby
end

if !ENV['TRAVIS'] || ENV['DB'] == 'postgresql'
  gem 'activerecord-jdbcpostgresql-adapter', :platform => :jruby
  gem 'pg', :platform => :ruby
end

gem 'jruby-openssl', :platform => :jruby

group :test do
  gem 'refinerycms-testing'
  gem 'generator_spec', '~> 0.9.0'
  gem 'guard-rspec', '~> 3.0.2'
  gem 'capybara-email', '~> 2.1.3'

  platforms :mswin, :mingw do
    gem 'win32console', '~> 1.3.0'
    gem 'rb-fchange', '~> 0.0.5'
    gem 'rb-notifu', '~> 0.0.4'
  end

  platforms :ruby do
    unless ENV['TRAVIS']
      require 'rbconfig'
      if /darwin/i === RbConfig::CONFIG['target_os']
        gem 'rb-fsevent', '~> 0.9.0'
        gem 'ruby_gntp', '~> 0.3.4'
      end
      if /linux/i === RbConfig::CONFIG['target_os']
        gem 'rb-inotify', '~> 0.9.0'
        gem 'libnotify',  '~> 0.8.1'
        gem 'therubyracer', '~> 0.11.4'
      end
    end
  end

  platforms :jruby do
    unless ENV['TRAVIS']
      require 'rbconfig'
      if /darwin/i === RbConfig::CONFIG['target_os']
        gem 'ruby_gntp', '~> 0.3.4'
      end
      if /linux/i === RbConfig::CONFIG['target_os']
        gem 'rb-inotify', '~> 0.9.0'
        gem 'libnotify',  '~> 0.8.1'
      end
    end
  end
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails', '~> 4.0.0'
gem 'uglifier'

gem 'turbolinks', '~> 1.2.0'

gem 'jquery-rails', '~> 3.0.1'
gem 'jquery-ui-rails', '~> 4.0.2'

gem 'will_paginate', '~> 3.0.4'
gem 'protected_attributes'

gem 'seo_meta', github: 'parndt/seo_meta', branch: 'master'
gem 'paper_trail', github: 'airblade/paper_trail', :branch => 'rails4'
gem 'database_cleaner', github: 'tommeier/database_cleaner', branch: 'fix-superclass'
gem 'globalize3', github: 'svenfuchs/globalize3', branch: 'rails4'
gem 'awesome_nested_set', github: 'collectiveidea/awesome_nested_set', branch: 'rails4'
gem 'routing-filter', github: "svenfuchs/routing-filter"
gem 'refinerycms-acts-as-indexed', github: 'refinery/refinerycms-acts-as-indexed'

gem 'friendly_id', github: 'FriendlyId/friendly_id', branch: 'master'

# Load local gems according to Refinery developer preference.
if File.exist? local_gemfile = File.expand_path('../.gemfile', __FILE__)
  eval File.read(local_gemfile)
end
