module Refinery
  module Pages
    # A type of SectionPresenter which knows how to render a section which displays
    # a PagePart model.
    class PagePartSectionPresenter < SectionPresenter
      def initialize(page_part)
        super()
        self.fallback_html = page_part.body.html_safe if page_part.body
        self.id = page_part.title
        self.hide unless page_part.active
      end

      private

      def wrap_content_in_tag(content)
        content_tag(:section, content_tag(:div, content, class: 'inner'), id: id, itemprop: Pages.part_to_item_property[self.id])
      end

    end
  end
end
