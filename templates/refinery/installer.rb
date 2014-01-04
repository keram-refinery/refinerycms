require 'rbconfig'

check_dependencies

VERSION_BAND = ::Refinery::Version.to_s

append_file 'Gemfile', <<-GEMFILE

# temporarily for solving dependency issues
gem 'friendly_id', github: 'norman/friendly_id', branch: 'master'
gem 'friendly_id-globalize', github: 'norman/friendly_id-globalize', branch: 'master'
gem 'paper_trail', github: 'airblade/paper_trail', branch: 'master'
gem 'globalize', github: 'globalize/globalize', branch: 'master'
gem 'routing-filter', github: 'svenfuchs/routing-filter', branch: 'master'
gem 'seo_meta', github: 'keram-refinerycms/seo_meta', branch: 'rails4'
gem 'awesome_nested_set', github: 'collectiveidea/awesome_nested_set', branch: 'master'
gem 'i18n-iso639matrix', '~> 0.0.1', github: 'keram/i18n-iso639matrix', branch: 'master'

# Refinery CMS
gem 'refinerycms', '~> #{VERSION_BAND}', github: 'keram-refinery/refinerycms', branch: 'refinery_light'
gem 'refinerycms-i18n', '~> #{VERSION_BAND}', github: 'keram-refinery/refinerycms-i18n', branch: 'refinery_light'
gem 'refinerycms-links', '~> 0.0.1', github: 'keram/refinerycms-links', branch: 'master'
gem 'refinerycms-clientside', '~> 0.0.1', github: 'keram-refinery/refinerycms-clientside', branch: 'master'

# Uncomment your preferred WYSIWYG editor and check out instalation guide for more details
#
# Epiceditor Installation Guide https://github.com/keram-refinery/refinerycms-epiceditor
# gem 'refinerycms-epiceditor', github: 'keram-refinery/refinerycms-epiceditor', branch: 'master'
#
# Tinymce Installation Guide https://github.com/keram/refinerycms-tinymce
# gem 'refinerycms-tinymce', github: 'keram/refinerycms-tinymce', branch: 'master'

# Specify additional Refinery CMS Extensions here (all optional):
#  gem 'refinerycms-blog', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-blog', branch: 'refinery_light'
#  gem 'refinerycms-inquiries', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-inquiries', branch: 'refinery_light'
#  gem 'refinerycms-calendar', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-calendar', branch: 'refinery_light'
#  gem 'refinerycms-search', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-search', branch: 'refinery_light'
#  gem 'refinerycms-page-images', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-page-images', branch: 'refinery_light'

GEMFILE

run 'bundle install'

rake 'db:create'
generate "refinery:cms --fresh-installation #{::ARGV.join(' ')}"

say <<-SAY
  ============================================================================
    Your new Refinery CMS application is now installed and mounts at '/'
  ============================================================================
SAY
