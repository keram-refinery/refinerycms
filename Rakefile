#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rspec/core'
require 'rspec/core/rake_task'
require 'refinerycms-testing'

RSpec::Core::RakeTask.new(:spec)
Bundler::GemHelper.install_tasks

APP_RAKEFILE = File.expand_path('../spec/dummy/Rakefile', __FILE__)

if File.exist?(APP_RAKEFILE)
  load 'rails/tasks/engine.rake'
end

Dir[File.expand_path('../tasks/**/*', __FILE__)].each do |task|
  load task
end


Refinery::Testing::Railtie.load_dummy_tasks File.dirname(__FILE__)

desc 'Build gem files for all projects'
task :build => 'all:build'

task :default => :spec
