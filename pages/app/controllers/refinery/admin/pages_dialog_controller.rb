module Refinery
  module Admin
    class PagesDialogController < ::Refinery::AdminDialogController

      def index
        @pages = Page.roots.with_globalize.paginate(
                    page: paginate_page, per_page: paginate_per_page)
      end

    protected

      def paginate_per_page
        Pages.per_dialog_page
      end

    end
  end
end
