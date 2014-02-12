module Refinery
  module Admin
    class ImagesDialogController < AdminDialogController

      helper Refinery::Admin::ImagesHelper

      def index
        find_images
        @image = Image.new
      end

      def create
        begin
          image = Image.create(image_params)
        rescue Dragonfly::Shell::CommandFailed
          logger.warn($!.message)
        end

        @image = image.valid? ? Image.new : image

        if image.valid?
          json_response image: image.to_images_dialog
        else
          flash.now[:alert] = t('problem_create_images',
                      images: image.image_name,
                      scope: 'refinery.admin.images')
        end

        find_images
        render :index
      end

    protected

      def paginate_per_page
        Images.per_dialog_page
      end

      def find_images
        @images ||= Image.paginate(page: paginate_page, per_page: paginate_per_page)
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
