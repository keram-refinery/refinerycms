require "spec_helper"

module Refinery
  describe 'site bar', type: :feature do
    refinery_login_with :refinery_user

    it 'have logout link' do
      visit refinery.admin_root_path

      page.should have_content("Log out")
      page.should have_selector("a[href='/#{Refinery::Core.backend_route}/logout']")
    end

    context 'when in backend' do
      before { visit refinery.admin_root_path }

      it "have a 'switch to your website button'" do
        page.should have_content("Website")
        page.should have_selector("a[href='/']")
      end

      it 'switches to frontend' do
        page.current_path.should == refinery.admin_root_path
        click_link "Website"
        page.current_path.should == refinery.root_path
      end
    end

    context 'when in frontend' do
      before do
        # make a page in order to avoid 404
        FactoryGirl.create(:page, :link_url => '/', :plugin_page_id => 'pages')

        visit refinery.root_path
      end

      it "have a 'switch to your website editor' button" do
        page.should have_content("Administration")
        page.should have_selector("a[href='/refinery']")
      end

      it 'switches to backend' do
        page.current_path.should == refinery.root_path
        click_link "Administration"
        page.current_path.should == refinery.admin_root_path
      end
    end
  end
end
