module Refinery
  module Admin
    class ImagesController < AdminController

      crudify :'refinery/image',
              sortable: false

      before_action :change_list_mode_if_specified, only: [:index]

      before_action :find_images_or_error_not_found, only: [:edit, :update, :destroy]
      before_action :images_list, only: [:edit, :update]

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
            rescue Dragonfly::Shell::CommandFailed
              invalid_images << @image
            end
          end
        end

        if invalid_images.any?
          create_unsuccessful invalid_images
        else
          redirect_to redirect_url, status: :see_other
        end
      end

      def update
        if images_list.update(images_list_params)
          flash.notice = t(
            'refinery.crudify.updated',
            kind: t(Image.model_name.i18n_key, scope: 'activerecord.models'),
            what: images_list.title
          )

          redirect_to redirect_url
        else
          render action: :edit
        end
      end

      def destroy
        title = find_images.map(&:name).join("', '")

        if @images.map(&:destroy)
          flash.notice = t(
            'refinery.crudify.destroyed',
            kind: t(Image.model_name.i18n_key, scope: 'activerecord.models'),
            what: title
          )
        end

        redirect_to refinery.admin_images_path, status: :see_other
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

        render action: :new
      end

      def redirect_url
        if @images.any?
          refinery.edit_admin_image_path(images_list,
            locale: (params[:switch_frontend_locale].presence || Globalize.locale))
        else
          refinery.admin_images_path
        end
      end

      def find_image
        @image ||= find_images.first
      end

      def find_images
        @images ||= [].tap do |arr|
          params[:id].split('-').each do |id|
            if (img = Refinery::Image.find_by(id: id))
              arr << img
            end
          end
        end
      end

      def images_list
        @images_list ||= Refinery::ImagesList.new(find_images)
      end

      def images_list_params
        params.require(:images_list).permit(image: [:alt, :caption, :image])
      end

      def find_images_or_error_not_found
        find_images.any? || error_404
      end

    end
  end
end
