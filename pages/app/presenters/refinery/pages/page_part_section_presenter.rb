module Refinery
  module Pages
    # A type of SectionPresenter which knows how to render a section which displays
    # a PagePart model.
    class PagePartSectionPresenter < SectionPresenter
      def initialize(page_part)
        super()
        @content = page_part.body
        @id = page_part.title
        @hidden = !page_part.active
      end
    end
  end
end
