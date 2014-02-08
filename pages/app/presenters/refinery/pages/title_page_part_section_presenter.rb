module Refinery
  module Pages
    class TitlePagePartSectionPresenter < PagePartSectionPresenter
      def initialize(page_part, context=nil)
        super
        @content = page_part.body.presence || page_part.page.title
      end

      private

      def main_content
        content_tag(:h1, content, id: id, itemprop: Pages.part_to_item_property[self.id])
      end

    end
  end
end
