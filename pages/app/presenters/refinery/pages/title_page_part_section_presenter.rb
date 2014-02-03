module Refinery
  module Pages
    class TitlePagePartSectionPresenter < SectionPresenter
      def initialize(page_part)
        super()
        @content = page_part.body.presence || page_part.page.title
        @id = page_part.title
        @hidden = !page_part.active
      end

      private

      def wrap_content_in_tag(content)
        content_tag(:h1, content, id: id, itemprop: Pages.part_to_item_property[self.id])
      end

      def content_renderer
        @@content_renderer ||= Refinery::ContentRenderer.new
      end

      def render_content content
        content_renderer.render(content)
      end
    end
  end
end
