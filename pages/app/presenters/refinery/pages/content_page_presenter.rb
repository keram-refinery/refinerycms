module Refinery
  module Pages
    # A type of ContentPresenter which specifically knows how to render the html
    # for a Refinery::Page object. Pass the page object into the constructor,
    # and it will build sections from the page's parts. The page is not retained
    # internally, so if the page changes, you need to rebuild this ContentPagePresenter.
    class ContentPagePresenter < ContentPresenter
      def initialize(page)
        super()
        if page
          add_page_parts(page.parts)
          @item_type = {
            itemscope: :itemscope,
            itemtype: "http://schema.org/#{page.page_type}"
          }
        end
      end

    private

      def add_page_parts(parts)
        parts.each do |part|
          presenter = "Refinery::Pages::#{part.title.to_s.classify}PagePartSectionPresenter".safe_constantize ||
                      PagePartSectionPresenter

          Refinery::Pages.get_extras(:before, part.title).each do |key, proc|
            add_section proc.call(part.page, :before, part.title)
          end

          add_section presenter.new(part)

          Refinery::Pages.get_extras(:after, part.title).each do |key, proc|
            add_section proc.call(part.page, :after, part.title)
          end

        end
      end

      def item_type
        @item_type ||= { }
      end
    end
  end
end
