# encoding: utf-8
require 'spec_helper'

def new_window_should_have_content(content)
  new_window = page.driver.browser.window_handles.last
  page.within_window new_window do
    page.should have_content(content)
  end
end

def new_window_should_not_have_content(content)
  new_window = page.driver.browser.window_handles.last
  page.within_window new_window do
    page.should_not have_content(content)
  end
end

module Refinery
  module Admin
    describe 'Pages', type: :feature do
      refinery_login_with :refinery_user

      describe 'Previewing' do
        context "an existing page" do
          before { Page.create title: 'Preview me' }

          it 'will show the preview changes in a new window', :js do
            visit refinery.admin_pages_path

            click_link 'Edit this page'
            fill_in "Title", with: "Some changes I'm unsure what they will look like"
            click_link 'Preview'

            new_window_should_have_content("Some changes I'm unsure what they will look like")
          end

          it 'will not show the site bar', :js do
            visit refinery.admin_pages_path

            click_link 'Edit this page'
            fill_in "Title", with: "Some changes I'm unsure what they will look like"
            click_link 'Preview'

            new_window_should_not_have_content(
              ::I18n.t('switch_to_website', scope: 'refinery.site_bar')
            )
            new_window_should_not_have_content(
              ::I18n.t('switch_to_website_editor', scope: 'refinery.site_bar')
            )
          end

          it 'will not save the preview changes', :js do
            visit refinery.admin_pages_path

            click_link 'Edit this page'
            fill_in "Title", with: "Some changes I'm unsure what they will look like"
            click_link 'Preview'

            new_window_should_have_content("Some changes I'm unsure what they will look like")

            Page.by_title("Some changes I'm unsure what they will look like").should be_empty
          end

          # Regression test for previewing after save-and_continue
          it 'will show the preview in a new window after save-and-continue', :js do
            visit refinery.admin_pages_path

            click_link 'Edit this page'
            fill_in "Title", with: "Save this"
            first('.submit-button').click # "Save draft"
            page.should have_content("'Save this' was successfully updated")

            click_link 'Preview'

            new_window_should_have_content("Save this")
            new_window_should_not_have_content(
              ::I18n.t('switch_to_website', scope: 'refinery.site_bar')
            )
          end
        end

        context 'a brand new page' do
          it "will not save when just previewing", :js do
            visit refinery.admin_pages_path

            click_link "Add new page"
            fill_in "Title", with: "My first page"
            click_link 'Preview'

            new_window_should_have_content("My first page")

            Page.count.should == 0
          end
        end

        context 'a nested page' do
          let!(:parent_page) { Page.create title: "Our Parent Page" }
          let!(:nested_page) { parent_page.children.create title: 'Preview Me' }

          it "works like an un-nested page", :js do
            visit refinery.admin_pages_path

            within "#page_#{nested_page.id}" do
              click_link 'Edit this page'
            end

            fill_in "Title", with: "Some changes I'm unsure what they will look like"
            click_link 'Preview'

            new_window_should_have_content("Some changes I'm unsure what they will look like")
          end
        end
      end

    end
  end
end
