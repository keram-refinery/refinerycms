module Refinery
  module Pages
    class SideBodyPagePartSectionPresenter < PagePartSectionPresenter

      private

      def main_content
        content_tag(:aside, content_tag(:div, content, class: 'inner'),
                    id: id,
                    role: 'complementary',
                    itemprop: Pages.part_to_item_property[self.id])
      end
    end
  end
end
