module Refinery
  module Pages
    class SideBodyPagePartSectionPresenter < PagePartSectionPresenter

      private

      def wrap_content_in_tag(content)
        content_tag(:aside, content_tag(:div, content, :class => 'inner'), :id => id)
      end
    end
  end
end
