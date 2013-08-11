require 'spec_helper'

describe 'dashboard' do
  refinery_login_with :refinery_user

  describe 'quick tasks' do
    specify 'buttons' do
      visit refinery.admin_root_path

      page.should have_content(::I18n.t('quick_tasks', :scope => 'refinery.admin.dashboard.index'))

      # add new page
      page.should have_content(::I18n.t('add_a_new_page', :scope => 'refinery.admin.dashboard.actions'))
      page.should have_selector("a[href='#{refinery.new_admin_page_path}']")

      # upload file
      if defined? Refinery::Resource
        page.should have_content(::I18n.t('upload_a_file', :scope => 'refinery.admin.dashboard.actions'))
        page.should have_selector("a[href*='#{refinery.new_admin_resource_path}']")
      end

      # upload image
      if defined? Refinery::Image
        page.should have_content(::I18n.t('upload_a_image', :scope => 'refinery.admin.dashboard.actions'))
        page.should have_selector("a[href*='#{refinery.new_admin_image_path}']")
      end
    end
  end

  describe 'latest activity' do
    before do
      3.times { |n| FactoryGirl.create :refinery_user, :username => "ugisozols#{n}" }
      3.times { |n| FactoryGirl.create :page, :title => "Refinery CMS #{n}" }
    end

    it 'shows created tracked objects' do
      visit refinery.admin_root_path

      within '#content' do
        page.should have_content('Latest Activity')
        3.times { |n| page.should have_content("Ugisozols#{n} user was added") }
        3.times { |n| page.should have_content("Refinery cms #{n} page was added") }
      end
    end

    # see https://github.com/refinery/refinerycms/issues/1673
    it 'uses proper link for nested pages' do
      # we need to increase updated_at because dashboard entries are sorted by
      # updated_at column and we need this page to be at the top of the list
      #
      nested = FactoryGirl.create(:page, :parent_id => Refinery::Page.last.id,
                                         :updated_at => Time.now + 10.seconds)
      visit refinery.admin_root_path
      page.should have_selector("a[href='#{refinery.edit_admin_page_path(nested)}']")
    end

#    # see https://github.com/refinery/refinerycms/issues/1673
#    it 'uses proper link for nested pages' do
#      # we need to increase updated_at because dashboard entries are sorted by
#      # updated_at column and we need this page to be at the top of the list
#      nested = FactoryGirl.create(:page, :parent_id => Refinery::Page.last.id,
#                                         :updated_at => Time.now + 10.seconds)
#
#      visit refinery.admin_root_path
#
#      page.should have_selector("a[href='#{refinery.edit_admin_page_path(nested.nested_url)}']")
#    end
  end
end
