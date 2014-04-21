module Refinery
  module Pages
    class SideBodyPagePartSectionPresenter < PagePartSectionPresenter

      protected

      def section_role
        'complementary'
      end

      def section_tag
        :aside
      end
    end
  end
end
