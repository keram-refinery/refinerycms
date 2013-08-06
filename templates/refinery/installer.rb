require 'rbconfig'

ROOT_PATH = File.expand_path('../../../', __FILE__)
require "#{ROOT_PATH}/core/lib/refinery/version.rb"

VERSION_BAND = Refinery::Version.to_s

check_dependencies

append_file 'Gemfile', <<-GEMFILE

# Refinery CMS
gem 'refinerycms', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms.git', :branch => 'refinery_light'
gem 'refinerycms-i18n', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms-i18n.git', :branch => 'refinery_light'

# Specify additional Refinery CMS Extensions here (all optional):
#  gem 'refinerycms-blog', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms-blog.git', :branch => 'refinery_light'
#  gem 'refinerycms-inquiries', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms-inquiries.git', :branch => 'refinery_light'
#  gem 'refinerycms-calendar', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms-calendar.git', :branch => 'refinery_light'
#  gem 'refinerycms-search', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms-search.git', :branch => 'refinery_light'
#  gem 'refinerycms-page-images', '~> #{VERSION_BAND}' # :git => 'git://github.com/keram-refinery/refinerycms-page-images.git', :branch => 'refinery_light'

GEMFILE

run 'bundle install'

rake 'db:create'
generate "refinery:cms --fresh-installation #{ARGV.join(' ')}"

say <<-SAY
  ============================================================================
    Your new Refinery CMS application is now installed and mounts at '/'
  ============================================================================
SAY
