require 'rbconfig'

check_dependencies

VERSION_BAND = ::Refinery::Version.to_s

append_file 'Gemfile', <<-GEMFILE

# temporarily for solving dependency issues
gem 'filters_spam', '~> 0.4', github: 'parndt/filters_spam', branch: 'master'

# Refinery CMS
gem 'refinerycms', '~> #{VERSION_BAND}', github: 'keram-refinery/refinerycms', branch: 'refinery_light'
gem 'refinerycms-i18n', '~> #{VERSION_BAND}', github: 'keram-refinery/refinerycms-i18n', branch: 'refinery_light'
gem 'refinerycms-links', '~> 0.0.1', github: 'keram/refinerycms-links', branch: 'master'
gem 'refinerycms-clientside', '~> 0.0.1', github: 'keram-refinery/refinerycms-clientside', branch: 'master'
gem 'refinerycms-admin-search', '~> 1.0.0', github: 'keram/refinerycms-admin-search', branch: 'master'
gem 'refinerycms-imageable', '~> 0.0.1', github: 'keram/refinerycms-imageable', branch: 'master'

# Uncomment your preferred WYSIWYG editor and check out instalation guide for more details
#
# Epiceditor Installation Guide https://github.com/keram-refinery/refinerycms-epiceditor
# gem 'refinerycms-epiceditor', github: 'keram-refinery/refinerycms-epiceditor', branch: 'master'
#
# Tinymce Installation Guide https://github.com/keram/refinerycms-tinymce
# gem 'refinerycms-tinymce', github: 'keram/refinerycms-tinymce', branch: 'master'

# Specify additional Refinery CMS Extensions here (all optional):
#  gem 'refinerycms-blog2', '~> 1.0.0', github: 'keram/refinerycms-blog2', branch: 'refinery_light'
#  gem 'refinerycms-inquiries2', '~> 1.0.0', github: 'keram-refinery/refinerycms-inquiries', branch: 'refinery_light'
#  gem 'refinerycms-calendar', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-calendar', branch: 'refinery_light'
#  gem 'refinerycms-search', '~> #{VERSION_BAND}' # github: 'keram-refinery/refinerycms-search', branch: 'refinery_light'

GEMFILE

run 'bundle install'

rake 'db:create'
generate "refinery:cms --fresh-installation #{::ARGV.join(' ')}"

say <<-SAY
  ============================================================================
    Your new Refinery CMS application is now installed and mounts at '/'
  ============================================================================
SAY
