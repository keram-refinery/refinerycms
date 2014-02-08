require "spec_helper"

module Refinery
  module Pages
    describe SectionPresenter do
      it "can build a css class for when it is not present based on id" do
        section = SectionPresenter.new(:content => 'foobar', :id => 'mynode')
        section.not_present_css_class.should == 'no_mynode'
      end

      it "allows access to constructor arguments" do
        section = SectionPresenter.new(:content => 'foobar', :id => 'mynode', :hidden => true)
        section.content.should == 'foobar'
        section.id.should == 'mynode'
        section.should be_hidden
      end

      it "should be visible if not hidden" do
        section = SectionPresenter.new(:hidden => false)
        section.should be_visible
      end

      it "should be not visible if hidden" do
        section = SectionPresenter.new(:hidden => true)
        section.should_not be_visible
      end

      describe "when building html for a section" do
        it "wont show a hidden section" do
          section = SectionPresenter.new(:content => 'foobar', :hidden => true)
          section.has_content?.should be_true
          section.wrapped_html.should be_nil
        end

        it "will use the specified id" do
          section = SectionPresenter.new(:content => 'foobar', :id => 'mynode')
          section.has_content?.should be_true
          section.wrapped_html.should == "<div class=\"section-wrapper\" id=\"mynode-wrapper\"><div class=\"inner\"><section class=\"section\" id=\"mynode\"><div class=\"inner\">foobar</div></section></div></div>"
        end

        describe "if allowed to use fallback html" do
          it "wont show a section with no fallback or override" do
            section = SectionPresenter.new
            section.has_content?.should be_false
            section.wrapped_html.should be_nil
          end

          it "uses wrapped fallback html" do
            section = SectionPresenter.new(:content => 'foobar')
            section.has_content?.should be_true
            section.wrapped_html.should == "<div class=\"section-wrapper\"><div class=\"inner\"><section class=\"section\"><div class=\"inner\">foobar</div></section></div></div>"
          end
        end
      end
    end
  end
end
