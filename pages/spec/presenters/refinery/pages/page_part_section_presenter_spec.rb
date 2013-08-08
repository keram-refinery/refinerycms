require "spec_helper"

module Refinery
  module Pages
    describe PagePartSectionPresenter do
      it "can be built from a page part" do
        part = double(PagePart, :body => 'A Wonderful Page Part', :title => :body, :active => true)
        section = PagePartSectionPresenter.new(part)
        section.fallback_html.should == 'A Wonderful Page Part'
        section.id.should == :body
      end

      it "marks the body as html safe" do
        part = double(PagePart, :body => '<p>part_body</p>', :title => nil, :active => true)
        section = PagePartSectionPresenter.new(part)
        section.fallback_html.should be_html_safe
        section.wrapped_html.should == "<section><div class=\"inner\"><p>part_body</p></div></section>"
      end

      it "handles a nil page body" do
        part = double(PagePart, :body => nil, :title => nil, :active => true)
        section = PagePartSectionPresenter.new(part)
        section.fallback_html.should be_nil
        section.wrapped_html.should be_nil
        section.has_content?.should be_false
      end

      it "has no id if title is nil" do
        part = double(PagePart, :body => 'foobar', :title => nil, :active => true)
        section = PagePartSectionPresenter.new(part)
        section.id.should be_nil
      end
    end
  end
end
