require 'rbconfig'

append_file 'Gemfile' do
"

gem 'refinerycms', :git => 'git://github.com/refinery/refinerycms.git'
gem 'refinerycms-i18n', :git => 'git://github.com/refinery/refinerycms-i18n.git'

# USER DEFINED

# Specify additional Refinery CMS Engines here (all optional):
#  gem 'refinerycms-acts-as-indexed', :git => 'git://github.com/refinery/refinerycms-acts-as-indexed.git'
#  gem 'refinerycms-blog', :git => 'git://github.com/refinery/refinerycms-blog.git'
#  gem 'refinerycms-inquiries', :git => 'git://github.com/refinery/refinerycms-inquiries.git'
#  gem 'refinerycms-calendar', :git => 'git://github.com/refinery/refinerycms-calendar.git'
#  gem 'refinerycms-search', :git => 'git://github.com/refinery/refinerycms-search.git'
#  gem 'refinerycms-page-images', :git => 'git://github.com/refinery/refinerycms-page-images.git'

# END USER DEFINED
"
end

run 'bundle install'
rake 'db:create'
generate "refinery:cms --fresh-installation #{ARGV.join(' ')}"

say <<-eos
  ============================================================================
    Your new Refinery CMS application is now running on edge and mounted to /.
  ============================================================================
eos
