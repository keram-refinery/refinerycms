module Refinery
  module Pages
    class FeaturedImagePagePartSectionPresenter < SectionPresenter
      include ::ActionView::Helpers::AssetTagHelper

      def initialize(page_part)
        super()

        if page_part.page.featured_image_id.present?
          self.fallback_html = image_tag(page_part.page.featured_image.url, role: 'banner')
        end

        self.id = page_part.title
        self.hide unless page_part.active
      end

      private


      def content_renderer
        @@content_renderer ||= Refinery::ContentRenderer.new
      end

      def render_content content
        content_renderer.render(content)
      end
    end
  end
end
