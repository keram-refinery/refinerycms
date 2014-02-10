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
    attr_reader :content
    attr_accessor :override_html
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
      override_html.present? || content.present?
    end

    def wrapped_html
      content_tag(:div,
        content_tag(:div, main_content, class: 'inner'),
        id: wrapper_id,
        class: wrapper_class
      ) if visible? && has_content?
    end

    def not_present_css_class
      "no_#{id}"
    end

  private

    def wrapper_id
      "#{id}-wrapper" if id.present?
    end

    def wrapper_class
      'section-wrapper'
    end

    def content_class
      'section'
    end

    def main_content
      content_tag(:section,
        content_tag(:div, override_html.presence || render_content(content), class: 'inner'),
        id: id,
        class: content_class)
    end

    def render_content content
      renderer.render content
    end

    def renderer
      @renderer ||= Refinery.content_renderer
    end
  end
end
