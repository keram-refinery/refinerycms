require "spec_helper"

module Refinery
  module Pages
    describe ContentPresenter do
      let(:section1) { double(SectionPresenter, :id => 'foo', :has_content? => true) }
      let(:section2) { double(SectionPresenter, :id => 'bar', :has_content? => true) }

      describe "when building css classes for blank sections" do
        let(:section) { double(SectionPresenter, :not_present_css_class => 'no_section1') }

        it "includes css class for any section which doesnt have content" do
          section.stub(:has_content?).and_return(false)
          content = ContentPresenter.new
          content.add_section section

          content.blank_section_css_classes.should == ['no_section1']
        end

        it "doesnt include sections which have content" do
          section.stub(:has_content?).and_return(true)
          content = ContentPresenter.new
          content.add_section section

          content.blank_section_css_classes.should be_empty
        end
      end

      describe "when rendering as html" do
        it "is empty section tag if it has no sections" do
          content = ContentPresenter.new
          content.to_html.should == "<section id=\"content\" class=\"\"></section>"
        end

        it "returns sections joined by a newline inside section tag" do
          section1.stub(:wrapped_html).and_return('foo')
          section2.stub(:wrapped_html).and_return('bar')
          content = ContentPresenter.new([section1, section2])
          content.to_html.should == "<section id=\"content\" class=\"\">foo\nbar</section>"
        end

        it "passes can_use_fallback option on to sections" do
          section1.should_receive(:wrapped_html).and_return('foo')
          content = ContentPresenter.new([section1])
          content.to_html.should == "<section id=\"content\" class=\"\">foo</section>"
        end

        it "doesnt include sections with nil content" do
          section1.stub(:wrapped_html).and_return('foo')
          section2.stub(:wrapped_html).and_return(nil)
          content = ContentPresenter.new([section1, section2])
          content.to_html.should == "<section id=\"content\" class=\"\">foo</section>"
        end
      end

      describe "when fetching template overrides" do
        before do
          @content = ContentPresenter.new
        end

        it "yields a section with an id and stores the result in its override html" do
          section = double(SectionPresenter, :id => 'foo')
          section.should_receive(:override_html=).with('some override')
          @content.add_section section

          @content.fetch_template_overrides do |section_id|
            section_id.should == 'foo'
            'some override'
          end
        end

        it "doesnt yield a section without an id" do
          section = double(SectionPresenter, :id => nil)
          section.should_receive(:override_html=).never
          @content.add_section section

          @content.fetch_template_overrides do |section_id|
            raise "this should not occur"
          end
        end
      end
    end
  end
end
