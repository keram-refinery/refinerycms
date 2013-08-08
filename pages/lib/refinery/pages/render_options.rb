module Refinery
  module Pages
    module RenderOptions

      def render_options_for_template(page)
        {
          layout: page.layout_template,
          template: "refinery/pages/#{page.view_template}"
        }
      end

      def render_with_templates?(page = @page, render_options = {})
        render_options.update render_options_for_template(page)
        render render_options
      end

      protected :render_options_for_template, :render_with_templates?

    end
  end
end
