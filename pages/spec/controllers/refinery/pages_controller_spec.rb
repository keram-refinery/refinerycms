require 'spec_helper'

module Refinery
  describe PagesController do
    before do
      FactoryGirl.create(:page, :plugin_page_id => 'pages', :link_url => '/')
      FactoryGirl.create(:page, :title => 'test')
    end

    describe '#home' do
      it 'renders home template' do
        get :home
        expect(response).to render_template('home')
      end
    end

    describe '#show' do
      it 'renders show template' do
        request.stub(:fullpath).and_return('/test')
        get :show, :path => 'test'
        request.unstub(:fullpath)

        expect(response).to render_template('show')
      end
    end
  end
end
