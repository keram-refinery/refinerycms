require 'rbconfig'

check_dependencies

append_file 'Gemfile' do
"

gem 'refinerycms', github: 'keram-refinery/refinerycms',  branch: 'refinery_light'
gem 'refinerycms-i18n', github: 'keram-refinery/refinerycms-i18n',  branch: 'refinery_light'
gem 'refinerycms-links', '~> 0.0.1', github: 'keram/refinerycms-links', branch: 'master'
gem 'refinerycms-clientside', '~> 0.0.1', github: 'keram-refinery/refinerycms-clientside', branch: 'master'

# USER DEFINED

# Uncomment your preferred WYSIWYG editor and check out instalation guide for more details
#
# Epiceditor Installation Guide https://github.com/keram-refinery/refinerycms-epiceditor
# gem 'refinerycms-epiceditor', github: 'keram-refinery/refinerycms-epiceditor', branch: 'master'
#
# Tinymce Installation Guide https://github.com/keram/refinerycms-tinymce
# gem 'refinerycms-tinymce', github: 'keram/refinerycms-tinymce', branch: 'master'

# Specify additional Refinery CMS Engines here (all optional):
#  gem 'refinerycms-acts-as-indexed', github: 'keram-refinery/refinerycms-acts-as-indexed',  branch: 'refinery_light'
#  gem 'refinerycms-blog', github: 'keram-refinery/refinerycms-blog',  branch: 'refinery_light'
#  gem 'refinerycms-inquiries', github: 'keram-refinery/refinerycms-inquiries',  branch: 'refinery_light'
#  gem 'refinerycms-calendar', github: 'keram-refinery/refinerycms-calendar',  branch: 'refinery_light'
#  gem 'refinerycms-search', github: 'keram-refinery/refinerycms-search',  branch: 'refinery_light'
#  gem 'refinerycms-page-images', github: 'keram-refinery/refinerycms-page-images',  branch: 'refinery_light'

# END USER DEFINED
"
end

run 'bundle install'

rake 'db:create'
generate "refinery:cms --fresh-installation #{ARGV.join(' ')}"

say <<-SAY
  ============================================================================
    Your new Refinery CMS application is now running on edge and mounted to /.
  ============================================================================
SAY
