module Refinery
  module Admin
    class ResourcesDialogController < ::Refinery::AdminDialogController

      def index
        @resources = Resource.paginate(:page => paginate_page, :per_page => paginate_per_page)
      end


    protected

      def paginate_per_page
        Resources.per_dialog_page
      end

    end
  end
end
