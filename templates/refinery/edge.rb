require 'rbconfig'

check_dependencies

append_file 'Gemfile' do
"

gem 'refinerycms', :git => 'git://github.com/keram-refinery/refinerycms.git', :branch => 'refinery_light'
gem 'refinerycms-i18n', :git => 'git://github.com/keram-refinery/refinerycms-i18n.git', :branch => 'refinery_light'

# USER DEFINED

# Specify additional Refinery CMS Engines here (all optional):
#  gem 'refinerycms-acts-as-indexed', :git => 'git://github.com/keram-refinery/refinerycms-acts-as-indexed.git', :branch => 'refinery_light'
#  gem 'refinerycms-blog', :git => 'git://github.com/keram-refinery/refinerycms-blog.git', :branch => 'refinery_light'
#  gem 'refinerycms-inquiries', :git => 'git://github.com/keram-refinery/refinerycms-inquiries.git', :branch => 'refinery_light'
#  gem 'refinerycms-calendar', :git => 'git://github.com/keram-refinery/refinerycms-calendar.git', :branch => 'refinery_light'
#  gem 'refinerycms-search', :git => 'git://github.com/keram-refinery/refinerycms-search.git', :branch => 'refinery_light'
#  gem 'refinerycms-page-images', :git => 'git://github.com/keram-refinery/refinerycms-page-images.git', :branch => 'refinery_light'

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
