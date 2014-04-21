module Refinery
  module Pages
    # A type of ContentPresenter which specifically knows how to render the html
    # for a Refinery::Page object. Pass the page object into the constructor,
    # and it will build sections from the page's parts. The page is not retained
    # internally, so if the page changes, you need to rebuild this ContentPagePresenter.
    class ContentPagePresenter < ContentPresenter
      def initialize(page, context=nil)
        super()

        @context = context
        @item_type = page.page_type

        add_page_parts(page.parts)
      end

    private

      def add_page_parts(parts)
        parts.each do |part|
          presenter = "Refinery::Pages::#{part.title.to_s.classify}PagePartSectionPresenter".safe_constantize ||
                      PagePartSectionPresenter

          add_section presenter.new(part, @context)
        end
      end

    end
  end
end
