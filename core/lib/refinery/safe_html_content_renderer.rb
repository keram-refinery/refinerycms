module Refinery
  class SafeHtmlContentRenderer

    def initialize(renderer=nil)
      @original_renderer = renderer
    end

    def render(string='')
      return unless string.present?

      return @original_renderer.render(string.html_safe) if @original_renderer.respond_to?(:render)
      string.html_safe
    end

  end
end
