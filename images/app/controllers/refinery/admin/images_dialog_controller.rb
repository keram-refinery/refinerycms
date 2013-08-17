module Refinery
  module Admin
    class ImagesDialogController < AdminDialogController

      helper Refinery::Admin::ImagesHelper

      def index
        @images = Image.paginate(page: paginate_page, per_page: paginate_per_page)
        @image = Image.new
      end

      def create
        begin
          @image = Image.create(image_params)
        rescue Dragonfly::FunctionManager::UnableToHandle
          logger.warn($!.message)
        end

        if @image.valid?
          json_response image: { id: @image.id }
          index
          json_response html: { 'existing-image-area' => render_html_to_json_string('existing_image') }
          json_response html: render_html_to_json_string('upload_image')
        else
          flash.now[:alert] = t('problem_create_images',
                      images: @image.image_name,
                      scope: 'refinery.admin.images')
        end
      end

    protected

      def paginate_per_page
        Images.per_dialog_page
      end

    private

      def image_params
        if params[:image].present? && params[:image][:image].present?
          { image: params[:image][:image] }
        end
      end

    end
  end
end
