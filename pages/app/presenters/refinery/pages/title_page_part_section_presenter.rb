module Refinery
  module Pages
    class TitlePagePartSectionPresenter < PagePartSectionPresenter
      def initialize(page_part, context=nil)
        super
        @content = page_part.body.presence || page_part.page.title
      end

      protected

      def section_tag
        :h1
      end

    end
  end
end
