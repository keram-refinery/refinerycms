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

def stub_frontend_locales *locales
  Refinery::I18n.stub(:frontend_locales).and_return(locales)
  Refinery::AdminController.any_instance.stub(:frontend_locales_rgxp).and_return(%r{\A(#{::Refinery::I18n.frontend_locales.join('|')})\z})
  RoutingFilter::RefineryLocales.any_instance.stub(:locales_regexp).and_return(%r{^/(#{::Refinery::I18n.frontend_locales.join('|')})(/|$)})
end

def unstub_frontend_locales
  Refinery::I18n.unstub(:frontend_locales)
  Refinery::AdminController.any_instance.unstub(:frontend_locales_rgxp)
  RoutingFilter::RefineryLocales.any_instance.unstub(:locales_regexp)
  Globalize.locale = Refinery::I18n.default_frontend_locale
  ::I18n.locale = Refinery::I18n.default_locale
end

module Refinery
  module Admin
    describe 'Pages' do
      refinery_login_with :refinery_user

      before do
        Refinery::Page.delete_all
      end

      after do
        Refinery::Page.delete_all
      end

      context 'when no pages' do
        it 'invites to create one' do
          visit refinery.admin_pages_path
          page.should have_content(%q{There are no pages yet. Click "Add new page" to add your first page.})
        end
      end

      describe 'action links' do
        it 'shows add new page link' do
          visit refinery.admin_pages_path

          within '#actions' do
            page.should have_content('Add new page')
            page.should have_selector("a[href='/#{Refinery::Core.backend_route}/pages/new']")
          end
        end

        context 'when some pages exist' do
          before { 2.times { |i| Page.create :title => "Page #{i}" } }

          it 'shows move page link' do
            visit refinery.admin_pages_path

            within "#records" do
              page.should have_selector("a[class='move nojs-hide icon-small move-icon']")
            end
          end
        end

        context 'when sub pages exist' do
          let!(:company) { Page.create :title => 'Our Company' }
          let!(:team) { company.children.create :title => 'Our Team' }
          let!(:locations) { company.children.create :title => 'Our Locations' }
          let!(:location) { locations.children.create :title => 'New York' }

          context 'with auto expand option turned off' do
            before do
              Refinery::Pages.stub(:auto_expand_admin_tree).and_return(false)

              visit refinery.admin_pages_path
            end

            it 'show parent page' do
              page.should have_content(company.title)
            end

            it "doesn't show children" do
              page.should_not have_content(team.title)
              page.should_not have_content(locations.title)
            end

            it "expands children", :js do
              within "#page_#{company.id}" do
                page.should have_content(company.title)
                find(".tree .toggle").click
              end

              page.should have_content(team.title)
              page.should have_content(locations.title)
            end

            it "expands children when nested mutliple levels deep", :js do
              find("#page_#{company.id} .toggle").click
              find("#page_#{locations.id} .toggle").click

              page.should have_content("New York")
            end
          end

          context 'with auto expand option turned on' do
            before do
              Refinery::Pages.stub(:auto_expand_admin_tree).and_return(true)

              visit refinery.admin_pages_path
            end

            it 'shows children' do
              page.should have_content(team.title)
              page.should have_content(locations.title)
            end
          end
        end
      end # describe 'Pages'

      describe 'new/create' do
        it 'allows to create page' do
          Refinery::Page.count.should == 0

          visit refinery.admin_pages_path

          click_link 'Add new page'

          fill_in 'page_title', :with => 'My first page'
          click_button 'Save'

          page.body.should =~ /My first page/

          Refinery::Page.count.should == 1
        end

      end

      describe 'update' do
        let!(:updatable_page) { Page.create :title => 'Update me' }

        before do
          visit refinery.admin_pages_path
          page.should have_content('Update me')
        end

        context 'when saving and returning to index' do
          it 'updates page' do
            click_link 'Edit this page'

            fill_in 'page_title', :with => 'Updated'
            click_button 'Save'

            updatable_page.title.should eq('Updated')
          end
        end

      end

      describe 'destroy' do
        context 'when page can be deleted' do
          before { Page.create :title => 'Delete me' }

          it 'will show delete button' do
            visit refinery.admin_pages_path

            click_link "Remove this page forever"

            Refinery::Page.count.should == 0
          end
        end

        context "when page can't be deleted" do
          before { Page.create :title => 'Indestructible', :deletable => false }

          it 'wont show delete button' do
            visit refinery.admin_pages_path

            page.should have_no_content("Remove this page forever")
            page.should have_no_selector("a[href='/#{Refinery::Core.backend_route}/pages/indestructible']")
          end
        end
      end

      context 'duplicate page titles' do
        before { Page.create :title => 'I was here first' }

        it 'will append UUID to url path' do
          visit refinery.new_admin_page_path

          fill_in 'page_title', :with => 'I was here first'
          click_button "Save"

          Refinery::Page.last.url[:path][0].should =~ /i-was-here-first-/
        end
      end


      # regression spec for https://github.com/refinery/refinerycms/issues/1891
      describe 'page part body' do
        before do
          page = Refinery::Page.create! :title => 'test'
          page.parts.each do |part|
            part.body = '<header class="regression">test</header>'
            part.save
          end
        end

        specify "html shouldn't be stripped" do
          visit refinery.admin_pages_path
          click_link 'Edit this page'
          page.should have_content('header class="regression"')
        end
      end
    end

    describe 'TranslatePages' do
      refinery_login_with :refinery_user

      before do
        Refinery::Page.delete_all
      end

      after do
        Refinery::Page.delete_all
      end

      context 'with translations' do
        before do
          stub_frontend_locales :en, :ru

          # Create a home page in both locales (needed to test menus)
          home_page = Globalize.with_locale(:en) do
            Page.create :title => 'Home',
                        :plugin_page_id => 'pages',
                        :link_url => '/'
          end

          Globalize.with_locale(:ru) do
            home_page.title = 'Домашняя страница'
            home_page.save
          end
        end

        after do
          unstub_frontend_locales
        end

        describe 'add a page with title for default locale' do
          before do
            visit refinery.admin_pages_path
            click_link "Add new page"
            fill_in 'page_title', :with => 'News'
            click_button "Save"
            visit refinery.admin_pages_path
          end

          it 'succeeds' do
            Refinery::Page.count.should == 2
          end

          it 'shows locale flag for page' do
            p = ::Refinery::Page.by_slug('news').first
            within "#page_#{p.id}" do
              page.should have_css('a[class="locale flag-en"]')
            end
          end

          it "shows in frontend menu for 'en' locale" do
            visit '/'

            within "#menu" do
              page.should have_content('News')
              page.should have_selector('a[href="/news"]')
            end
          end

          it "doesn't show in frontend menu for 'ru' locale" do
            visit "/ru"

            within "#menu" do
              # we should only have the home page in the menu
              page.should have_css('li', :count => 1)
            end
          end
        end

        describe 'add a page with title for both locales' do
          let(:en_page_title) { 'News' }
          let(:en_page_slug) { 'news' }
          let(:ru_page_title) { 'Новости' }
          let(:ru_page_slug) { 'новости' }
          let(:ru_page_slug_encoded) { '%D0%BD%D0%BE%D0%B2%D0%BE%D1%81%D1%82%D0%B8' }
          let!(:news_page) do
            _page = Globalize.with_locale(:en) {
              Page.create :title => en_page_title
            }
            Globalize.with_locale(:ru) do
              _page.title = ru_page_title
              _page.save
            end

            _page
          end

          it 'succeeds' do
            news_page.destroy!
            visit refinery.admin_pages_path

            click_link "Add new page"

            within '.locale-picker' do
              click_link "ru"
            end

            fill_in 'page_title', :with => ru_page_title
            click_button "Save"

            visit refinery.admin_pages_path

            within "#page_#{Page.last.id}" do
              click_link "Edit this page"
            end

            within '.locale-picker' do
              click_link "en"
            end

            fill_in 'page_title', :with => en_page_title
            click_button "Save"

            Refinery::Page.count.should == 2
          end

          it 'shows both locale flags for page' do
            visit refinery.admin_pages_path

            within "#page_#{news_page.id}" do
              page.should have_css('a[class="locale flag-en"]')
              page.should have_css('a[class="locale flag-ru"]')
            end
          end

          it 'shows title in admin menu in current admin locale' do
            visit refinery.admin_pages_path

            within "#page_#{news_page.id}" do
              page.should have_content(en_page_title)
            end
          end

          it 'shows correct language and slugs for default locale' do
            visit '/'

            within "#menu" do
              page.find_link(news_page.title)[:href].should include(en_page_slug)
            end
          end

          it 'shows correct language and slugs for second locale' do
            visit "/ru"

            within "#menu" do
              page.find_link(ru_page_title)[:href].should include(ru_page_slug_encoded)
            end
          end
        end

        describe 'add a page with title only for secondary locale' do
          let(:ru_page) {
            Globalize.with_locale(:ru) {
              Page.create :title => ru_page_title
            }
          }
          let(:ru_page_id) { ru_page.id }
          let(:ru_page_title) { 'Новости' }
          let(:ru_page_slug) { 'новости' }
          let(:ru_page_slug_encoded) { '%D0%BD%D0%BE%D0%B2%D0%BE%D1%81%D1%82%D0%B8' }

          before do
            ru_page
            visit refinery.admin_pages_path
          end

          it 'succeeds' do
            ru_page.destroy!
            click_link "Add new page"
            within '.locale-picker' do
              click_link "ru"
            end
            fill_in 'page_title', :with => ru_page_title
            click_button "Save"

            Refinery::Page.count.should == 2
          end

          it 'shows locale flag for page' do
            within "#page_#{ru_page_id}" do
              page.should have_css('a[class="locale flag-ru"]')
            end
          end

          it "doesn't show locale flag for primary locale" do
            within "#page_#{ru_page_id}" do
              page.should_not have_css('a[class="locale flag-en"]')
            end
          end

          it 'shows title in the admin menu' do
            within "#page_#{ru_page_id}" do
              page.should have_content(ru_page_title)
            end
          end

          it 'uses id instead of slug in admin' do
            within "#page_#{ru_page_id}" do
              page.find_link('Edit this page')[:href].should include(ru_page_id.to_s)
            end
          end

          it "shows in frontend menu for 'ru' locale" do
            visit "/ru"

            within "#menu" do
              page.should have_content(ru_page_title)
              page.should have_selector("a[href='/ru/#{ru_page_slug_encoded}']")
            end
          end

          it "won't show in frontend menu for 'en' locale" do
            visit '/'

            within "#menu" do
              # we should only have the home page in the menu
              page.should have_css('li', :count => 1)
            end
          end

          context "when page is a child page" do
            it 'succeeds' do
              ru_page.destroy!
              parent_page = Page.create(:title => "Parent page")
              sub_page = Globalize.with_locale(:ru) {
                Page.create :title => ru_page_title
                Page.create :title => ru_page_title, :parent_id => parent_page.id
              }
              sub_page.parent.should == parent_page
              visit refinery.admin_pages_path
              within "#page_#{sub_page.id}" do
                click_link "Edit"
              end
              fill_in 'page_title', :with => ru_page_title
              click_button "Save"
              within "#flash-wrapper" do
                page.should have_content("'#{ru_page_title}' was successfully updated")
              end
            end
          end
        end
      end

      describe 'add page to main locale' do
        it 'succeed' do
          visit refinery.admin_pages_path

          click_link 'Add new page'

          fill_in 'page_title', :with => 'Huh?'
          click_button 'Save'

          within '#flash-wrapper' do
            Refinery::Page.count.should == 1
          end
        end
      end

      describe 'add page to second locale' do
        before do
          stub_frontend_locales :en, :lv
          Page.create :title => 'First Page'
        end

        after do
          unstub_frontend_locales
        end

        it 'succeeds' do
          visit refinery.admin_pages_path

          click_link 'Add new page'

          within '.locale-picker' do
            click_link 'lv'
          end
          fill_in 'page_title', :with => 'Brīva vieta reklāmai'
          click_button 'Save'

          Refinery::Page.count.should == 2
        end
      end

      describe 'Pages Link-to Dialog' do
        before do
          stub_frontend_locales :en, :ru

          # Create a page in both locales
          about_page = Globalize.with_locale(:en) do
            Page.create :title => 'About'
          end

          Globalize.with_locale(:ru) do
            about_page.title = 'About Ru'
            about_page.save
          end
        end

        after do
          unstub_frontend_locales
        end

        let(:about_page) do
          page = Refinery::Page.last
          # we need page parts so that there's wymeditor
          Refinery::Pages.default_parts.each_with_index do |default_page_part, index|
            page.parts.create(:title => default_page_part, :body => nil, :position => index)
          end
          page
        end

        describe 'adding page link' do
          describe 'with relative urls' do
            it "shows Russian pages if we're editing the Russian locale" do
              visit refinery.admin_dialogs_pages_path :frontend_locale => :ru

              within '#pages-link-area' do
                page.should have_content('About Ru')
              end
              #page.should have_selector("a[href='/ru/about-ru']")
            end

            it 'shows default to the default locale if no query string is added' do
              visit refinery.admin_dialogs_pages_path

              within '#pages-link-area' do
                page.should have_content('About')
              end
              #page.should have_selector("a[href='/about']")
            end
          end

          describe 'with absolute urls' do
            it "shows Russian pages if we're editing the Russian locale" do
              visit refinery.admin_dialogs_pages_path :frontend_locale => :ru

              within '#pages-link-area' do
                page.should have_content('About Ru')
              end
              #page.should have_selector("a[href='http://www.example.com/ru/about-ru']")
            end

            it 'shows default to the default locale if no query string is added' do
              visit refinery.admin_dialogs_pages_path

              within '#pages-link-area' do
                page.should have_content('About')
              end
              #page.should have_selector("a[href='http://www.example.com/about']")
            end
          end
        end

      end
    end
  end
end
