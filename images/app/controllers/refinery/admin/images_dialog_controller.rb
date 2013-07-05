module Refinery
  module Admin
    class ImagesDialogController < ::Refinery::AdminDialogController

      helper Refinery::Admin::ImagesHelper

      def index
        @images = Image.paginate(:page => paginate_page, :per_page => paginate_per_page)
      end

    protected

      def paginate_per_page
        if app_dialog?
          Images.per_dialog_page
        else
          Images.per_dialog_page_that_have_size_options
        end
      end

    end
  end
end
