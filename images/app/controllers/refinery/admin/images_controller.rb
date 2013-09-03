module Refinery
  module Admin
    class ImagesController < AdminController

      crudify :'refinery/image',
              sortable: false

      before_action :change_list_mode_if_specified, only: [:index]

      IMAGES_VIEWS_RE = %r{^(#{::Refinery::Images.image_views.join('|')})}

      def new
        @image = ::Refinery::Image.new
      end

      def create
        @images = []
        invalid_images = []

        if params[:image].present? && params[:image][:image].is_a?(Array)
          params[:image][:image].each do |image|
            begin
              @image = ::Refinery::Image.create({image: image})

              if @image.valid?
                @images << @image
              else
                invalid_images << @image
              end
            rescue Dragonfly::FunctionManager::UnableToHandle
              logger.warn($!.message)
              invalid_images << @image.image_name
            end
          end
        end

        if invalid_images.any?
          create_unsuccessful invalid_images
        else
          if iframe?
            json_response redirect_to: refinery.admin_images_path
          else
            redirect_to refinery.admin_images_path, status: :see_other
          end
        end
      end

      def update
        if @image.update(params.require(:image).permit(:image))
          flash.notice = t(
            'refinery.crudify.updated',
            kind: t(Image.model_name.i18n_key, scope: 'activerecord.models'),
            what: "#{@image.title}"
          )

          if iframe?
            json_response redirect_to: refinery.admin_images_path
          else
            redirect_back_or_default refinery.admin_images_path
          end
        else
          @thumbnail = Image.find params[:id].to_s
          render action: 'edit'
        end
      end

    protected

      def change_list_mode_if_specified
        Images.preferred_image_view = params[:view] if params[:view] =~ IMAGES_VIEWS_RE
      end

      def paginate_per_page
        Images.per_admin_page
      end

      def create_unsuccessful invalid_images
        @image = invalid_images.fetch(0) { Image.new }

        if @images.any?
          flash.now[:notice] = t('created', scope: 'refinery.crudify',
                      kind: t(Image.model_name.i18n_key, scope: 'activerecord.models'),
                      what: "#{@images.map(&:title).join(", ")}")
        end

        unless invalid_images.empty? ||
                    (invalid_images.size == 1 && @image.errors.keys.first == :image_name)
          flash.now[:alert] = t('problem_create_images',
                         images: invalid_images.map(&:image_name).join(', '),
                        scope: 'refinery.admin.images')
        end

        render action: 'new'
      end

    private

    end
  end
end
