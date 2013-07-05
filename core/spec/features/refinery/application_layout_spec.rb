require 'spec_helper'

module Refinery
  describe 'layout' do
    refinery_login_with :refinery_user

    let(:home_page) do
      FactoryGirl.create :page, :title => 'Home', :plugin_page_id => 'refinery_pages'
    end

    describe 'body' do
      it "id is the page's canonical id" do
        visit refinery.url_for(home_page.url)

        page.should have_css 'body#home-page'
      end
    end
  end
end
