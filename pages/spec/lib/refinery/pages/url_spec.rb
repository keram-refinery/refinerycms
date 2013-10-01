require 'spec_helper'

module Refinery
  module Pages
    describe Url::Localised do
      describe '.handle?' do
        it 'returns true if link_url is present' do
          page = double(:page, link_url: '/')
          Url::Localised.handle?(page).should be_true
        end
      end

      describe '#url' do
        let(:page) { double(:page, link_url: '/test') }

        context 'when current frontend locale != default frontend locale' do
          it 'returns link_url prefixed with current frontend locale' do
            Globalize.stub(:locale).and_return(:lv)
            Refinery::I18n.stub(:default_frontend_locale).and_return(:en)
            Url::Localised.new(page).url.should eq('/lv/test')
          end
        end

        context 'when current frontend locale == default frontend locale' do
          it 'returns unaltered link_url' do
            Globalize.stub(:locale).and_return(:en)
            Refinery::I18n.stub(:default_frontend_locale).and_return(:en)
            Url::Localised.new(page).url.should eq('/test')
          end
        end
      end
    end

    describe Url::Marketable do
      describe '.handle?' do
        it 'returns true if marketable_url config is set to true' do
          page = double(:page)
          Refinery::Pages.stub(:marketable_url).and_return(true)
          Url::Marketable.handle?(page).should be_true
        end
      end

      describe '#url' do
        it 'returns hash' do
          page = double(:page, nested_url: 'test', translated_locales: [:en])
          Url::Marketable.new(page).url.should eq({
            controller: '/refinery/pages', action: 'show', only_path: true,
            path: 'test', id: nil, locale: :en
          })
        end
      end
    end

    describe Url::Normal do
      describe '.handle?' do
        it 'returns true if to_param is present' do
          page = double(:page, to_param: 'test')
          Url::Normal.handle?(page).should be_true
        end
      end

      describe '#url' do
        it 'returns hash' do
          page = double(:page, to_param: 'test')
          Url::Normal.new(page).url.should eq({
            controller: '/refinery/pages', action: 'show', only_path: true,
            path: nil, id: 'test'
          })
        end
      end
    end
  end
end
