require "spec_helper"

module Refinery
  module Admin
    describe PagesHelper do

      describe "#page_meta_information" do
        let(:page) { FactoryGirl.build(:page) }

        context 'when show_in_menu is false' do
          it "adds 'hidden' label" do
            page.show_in_menu = false

            helper.page_meta_information(page).should eq(%q{<span class="label">hidden</span>})
          end
        end

        context 'when draft is true' do
          it "adds 'draft' label" do
            page.draft = true

            helper.page_meta_information(page).should eq(%q{<span class="label notice">draft</span>})
          end
        end
      end

      describe "#any_page_title" do
        let(:page) { FactoryGirl.build(:page) }

        before do
          Globalize.with_locale(:en) do
            page.title = 'draft'
            page.save!
          end

          Globalize.with_locale(:lv) do
            page.title = 'melnraksts'
            page.save!
          end
        end

        context 'when title is present' do
          it 'returns it' do
            helper.any_page_title(page).should eq('draft')
          end
        end

        context "when title for current locale isn't available" do
          it 'returns existing title from translations' do
            Page.translation_class.where(:locale => :en).map(&:destroy)
            helper.any_page_title(page).should eq('melnraksts')
          end
        end
      end
    end
  end
end
