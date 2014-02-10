module Refinery
  # Knows how to render a set of sections as html. This can be used in any
  # Refinery view that is built from a group of sections. Pass the sections
  # into the constructor or call add_section on the instance, then render by
  # calling 'to_html'.
  class ContentPresenter
    include ActionView::Helpers::TagHelper

    def initialize(initial_sections = [], context=nil)
      @sections = initial_sections
      @context = context
    end

    def blank_section_css_classes
      @sections.reject {|section| section.has_content? }.map(&:not_present_css_class)
    end

    def hidden_sections
      @sections.select {|section| section.hidden? }
    end

    def fetch_template_overrides
      @sections.each do |section|
        section.override_html = yield section.id if section.id
      end
    end

    def add_section(new_section)
      @sections << new_section
    end

    def get_section(index)
      @sections[index]
    end

    def to_html
      content_tag :section, sections_html, {
                  id: 'content',
                  class: blank_section_css_classes.join(' ')
                }.merge!(item_type)
    end

  private

    def sections_html
      @sections.map { |section|
        section.wrapped_html
      }.compact.join("\n").html_safe
    end

    def has_section?(id)
      @sections.detect {|section| section.id == id}
    end

    def item_type
      @item_type ||= {}
    end

  end
end
