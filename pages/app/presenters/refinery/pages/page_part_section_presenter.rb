module Refinery
  module Pages
    # A type of SectionPresenter which knows how to render a section which displays
    # a PagePart model.
    class PagePartSectionPresenter < Refinery::SectionPresenter
      def initialize(page_part, context=nil)
        @context = context
        @content = page_part.body
        @id = page_part.title
        @hidden = !page_part.active
        @page_part = page_part
      end
    end
  end
end
