require 'spec_helper'

module Refinery
  describe PagesController do
    before do
      FactoryGirl.create(:page, :link_url => '/', :view_template => 'home')
      FactoryGirl.create(:page, :title => 'test', :view_template => 'show')
    end

    describe '#home' do
      it 'renders home template' do
        get :home
        expect(response).to render_template('home')
      end
    end

    describe '#show' do
      it 'renders show template' do
        get :show, :path => 'test'
        expect(response).to render_template('show')
      end
    end
  end
end
