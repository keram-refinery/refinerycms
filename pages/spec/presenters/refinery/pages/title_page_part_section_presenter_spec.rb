require "spec_helper"

module Refinery
  module Pages
    describe TitlePagePartSectionPresenter do
      describe "when building html for a section" do
        let(:part) { Struct.new(:body, :title, :active) }

        it "wraps a title section in a title element" do
          section = TitlePagePartSectionPresenter.new(part.new('foobar', '', true))
          section.has_content?.should be_true
          section.wrapped_html.should ==  "<div class=\"section-wrapper\"><div class=\"inner\"><h1 id=\"\">foobar</h1></div></div>"
        end

        it "will use the specified id" do
          section = TitlePagePartSectionPresenter.new(part.new('foobar', 'mynode', true))
          section.has_content?.should be_true
          section.wrapped_html.should ==  "<div class=\"section-wrapper\" id=\"mynode-wrapper\"><div class=\"inner\"><h1 id=\"mynode\">foobar</h1></div></div>"
        end
      end
    end
  end
end
