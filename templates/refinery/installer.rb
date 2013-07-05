require 'rbconfig'
ROOT_PATH = File.expand_path('../../../', __FILE__)
require "#{ROOT_PATH}/core/lib/refinery/version.rb"

VERSION_BAND = Refinery::Version.to_s

append_file 'Gemfile', <<-GEMFILE

# Refinery CMS
gem 'refinerycms', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms.git'
gem 'refinerycms-i18n', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms-i18n.git'

# Specify additional Refinery CMS Extensions here (all optional):
#  gem 'refinerycms-blog', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms-blog.git'
#  gem 'refinerycms-inquiries', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms-inquiries.git'
#  gem 'refinerycms-calendar', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms-calendar.git'
#  gem 'refinerycms-search', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms-search.git'
#  gem 'refinerycms-page-images', '~> #{VERSION_BAND}' # :git => 'git://github.com/refinery/refinerycms-page-images.git'
GEMFILE

run 'bundle install'
rake 'db:create'
generate "refinery:cms --fresh-installation #{ARGV.join(' ')}"

say <<-SAY
  ============================================================================
    Your new Refinery CMS application is now installed and mounts at '/'
  ============================================================================
SAY
