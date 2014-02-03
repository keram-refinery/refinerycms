require "spec_helper"

module Refinery
  module Pages
    describe ContentPagePresenter do
      let(:title) { 'This Great Page' }

      describe 'when building for page' do
        context 'withou body part' do
          let(:page_with_one_part) { FactoryGirl.create(:page, title: title) }

          before do
            body_part = page_with_one_part.part(:body)
            body_part.update(active: false, body: 'A Wonderful Page Part')
            side_part = page_with_one_part.part(:side_body)
            body_part.update(body: 'Another Wonderful Page Part')
          end

          it 'adds page title section before page parts' do
            content = ContentPagePresenter.new(page_with_one_part)
            content.get_section(0).content.should == title
          end

          it 'has body part hidden' do
            content = ContentPagePresenter.new(page_with_one_part)
            content.hidden_sections.map(&:id).should == [:perex, :body]
          end
        end

        context 'default parts' do
          let(:page) { FactoryGirl.create(:page) }

          before do
            body_part = page.part(:body)
            body_part.update(body: 'A Wonderful Page Part')
            side_part = page.part(:side_body)
            side_part.update(body: 'Another Wonderful Page Part')
          end

          it 'adds a section for each page part' do
            content = ContentPagePresenter.new(page)
            content.get_section(2).content.should == 'A Wonderful Page Part'
            content.get_section(3).content.should == 'Another Wonderful Page Part'
          end

          it 'adds body content left and right after page parts' do
            content = ContentPagePresenter.new(page)
            content.get_section(2).id.should == :body
            content.get_section(3).id.should == :side_body
          end

          it 'doesnt add title if it is blank' do
            content = ContentPagePresenter.new(nil)
            content.instance_variable_get(:@sections).should == []
          end
        end
      end
    end
  end
end
