require 'spec_helper'
require 'generator_spec/test_case'
require 'generators/refinery/engine/engine_generator'
require 'tmpdir'

module Refinery
  describe EngineGenerator do
    include GeneratorSpec::TestCase
    destination Dir.mktmpdir

    context 'when defining type of attribute in name' do
      before do
        run_generator %w{ rspec_item_test title:string site_url:string site_email:string site_phone:string site_color:string site_password:string }
      end

      after do
        FileUtils.rm_r(destination_root)
      end

      it 'generate proper html5 form fields' do
        File.open("#{destination_root}/vendor/extensions/rspec_item_tests/app/views/refinery/admin/rspec_item_tests/rspec_item_tests/_form.html.erb") do |file|
          file.read.tap do |c|
            c.should =~ %r{f.url_field :site_url}
            c.should =~ %r{f.email_field :site_email}
            c.should =~ %r{f.telephone_field :site_phone}
            c.should =~ %r{f.color_field :site_color}
            c.should =~ %r{f.password_field :site_password}
          end
        end

      end
    end

    context 'when defining type of attribute in type' do

      before do
        run_generator %w{ rspec_item_test title:string website:url mail:email mobil:phone colour:color passwd:password }
      end

      after do
        FileUtils.rm_r(destination_root)
      end

      it 'generate proper html5 form fields' do
        File.open("#{destination_root}/vendor/extensions/rspec_item_tests/app/views/refinery/admin/rspec_item_tests/rspec_item_tests/_form.html.erb") do |file|
          file.read.tap do |c|
            c.should =~ %r{f.url_field :website}
            c.should =~ %r{f.email_field :mail}
            c.should =~ %r{f.telephone_field :mobil}
            c.should =~ %r{f.color_field :colour}
            c.should =~ %r{f.password_field :passwd}
          end
        end
      end

      it 'generate proper database types for migration' do
        File.open("#{destination_root}/vendor/extensions/rspec_item_tests/db/migrate/1_create_rspec_item_tests_rspec_item_tests.rb") do |file|
          file.read.tap do |c|
            c.should =~ %r{t.string :website}
            c.should =~ %r{t.string :mail}
            c.should =~ %r{t.string :mobil}
            c.should =~ %r{t.string :colour}
            c.should =~ %r{t.string :passwd}
          end
        end
      end

    end

  end
end
