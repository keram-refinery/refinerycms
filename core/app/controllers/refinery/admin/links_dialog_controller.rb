module Refinery
  module Admin
    class LinksDialogController < ::Refinery::AdminDialogController

      def index
        @pages = ::Refinery::Page.roots.with_globalize.paginate(
                page: paginate_page, per_page: Pages.per_dialog_page)
      end

      protected

      def refinery_plugin
        @refinery_plugin ||= ::Refinery::Plugins['refinery_core']
      end

    end
  end
end
