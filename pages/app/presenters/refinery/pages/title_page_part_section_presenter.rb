module Refinery
  module Pages
    class TitlePagePartSectionPresenter < SectionPresenter
      def initialize(page_part)
        super()
        self.fallback_html = page_part.body.presence || page_part.page.title
        self.id = page_part.title
        self.hide unless page_part.active
      end

      private

      def wrap_content_in_tag(content)
        content_tag(:h1, content, id: id)
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
