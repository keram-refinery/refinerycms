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

    end
  end
end
