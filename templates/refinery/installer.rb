require 'rbconfig'

ROOT_PATH = File.expand_path('../../../', __FILE__)
require "#{ROOT_PATH}/core/lib/refinery/version.rb"

VERSION_BAND = Refinery::Version.to_s

check_dependencies

append_file 'Gemfile', <<-GEMFILE

# temporarily for solving dependency issues
gem 'friendly_id', github: 'norman/friendly_id', branch: 'master'
gem 'friendly_id-globalize', github: 'norman/friendly_id-globalize', branch: 'master'
gem 'paper_trail', github: 'airblade/paper_trail', branch: 'master'
gem 'globalize3', github: 'keram-refinery/globalize3', branch: 'rails4'
gem 'routing-filter', github: 'svenfuchs/routing-filter', branch: 'master'
gem 'seo_meta', github: 'parndt/seo_meta', branch: 'master'
gem 'awesome_nested_set', github: 'collectiveidea/awesome_nested_set', branch: 'master'

# Refinery CMS
gem 'refinerycms', '~> #{VERSION_BAND}', github: 'keram-refinery/refinerycms', branch: 'refinery_light'
gem 'refinerycms-i18n', '~> #{VERSION_BAND}', github: 'keram-refinery/refinerycms-i18n', branch: 'refinery_light'

# Specify your preferred WYSIWYG editor
gem 'refinery-epiceditor', github: 'keram-refinery/refinery-epiceditor', branch: 'master'

# Specify additional Refinery CMS Extensions here (all optional):
#  gem 'refinerycms-blog', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-blog', branch: 'refinery_light'
#  gem 'refinerycms-inquiries', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-inquiries', branch: 'refinery_light'
#  gem 'refinerycms-calendar', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-calendar', branch: 'refinery_light'
#  gem 'refinerycms-search', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-search', branch: 'refinery_light'
#  gem 'refinerycms-page-images', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-page-images', branch: 'refinery_light'

GEMFILE

run 'bundle install'

rake 'db:create'
generate "refinery:cms --fresh-installation #{ARGV.join(' ')}"

say <<-SAY
  ============================================================================
    Your new Refinery CMS application is now installed and mounts at '/'
  ============================================================================
SAY
