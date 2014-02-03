module Refinery
  # Knows how to build the html for a section. A section is part of the visible html, that has
  # content wrapped in some particular markup. Construct with the relevant options, and then
  # call wrapped_html to get the resultant html.
  #
  # The content rendered will usually be the value of content, unless an override_html
  # is specified. However, on rendering, you can elect not display sections that have no
  # override_html by passing in false for can_use_fallback.
  #
  # Sections may be hidden, in which case they wont display at all.
  class SectionPresenter
    include ActionView::Helpers::TagHelper

    attr_reader :id, :hidden
    attr_accessor :content
    alias_method :hidden?, :hidden

    def initialize section={}
      @content = section[:content]
      @id = section[:id]
      @hidden = section[:hidden]
    end

    def visible?
      !hidden?
    end

    def has_content?
      visible? && content.present?
    end

    def wrapped_html
      wrap_content_in_tag(render_content(content)) if has_content?
    end

    def not_present_css_class
      "no_#{id}"
    end

  protected

  private

    def wrap_content_in_tag(content)
      content_tag(:section, content_tag(:div, content, class: 'inner'), id: id)
    end

    def render_content content
      Refinery.content_renderer.render(content)
    end
  end
end
