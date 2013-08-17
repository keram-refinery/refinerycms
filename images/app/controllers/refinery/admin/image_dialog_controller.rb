module Refinery
  module Admin
    class ImageDialogController < ::Refinery::AdminDialogController

      helper Refinery::Admin::ImagesHelper

      def index
        @image = Image.find(params[:id].to_s)
      end

      protected

      def refinery_plugin
        @refinery_plugin ||= ::Refinery::Plugins['refinery_images']
      end

    end
  end
end
