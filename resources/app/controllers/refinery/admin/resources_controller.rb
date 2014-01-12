module Refinery
  module Admin
    class ResourcesController < ::Refinery::AdminController

      crudify :'refinery/resource',
              order: 'updated_at DESC',
              sortable: false

      def new
        @resource = Resource.new
      end

      def create
        @resources = []
        invalid_resources = []

        if params[:resource].present? && params[:resource][:file].is_a?(Array)
          params[:resource][:file].each do |resource|
            begin
              @resource = Resource.create({file: resource})

              if @resource.valid?
                @resources << @resource
              else
                invalid_resources << @resource
              end
            rescue Dragonfly::Shell::CommandFailed
              logger.warn($!.message)
            end
          end
        end

        if invalid_resources.any?
          create_unsuccessful invalid_resources
        else
          create_successful
        end
      end

      def update
        if @resource.update(resource_params)
          flash.notice = t(
            'refinery.crudify.updated',
            kind: t(Resource.model_name.i18n_key, scope: 'activerecord.models'),
            what: "#{@resource.title}"
          )

          redirect_to refinery.admin_resources_path, status: :see_other
        else
          restore_record_file_if_file_validation_fails
          render action: :edit
        end
      end

    protected

      def create_successful
        flash.notice = t('created', scope: 'refinery.crudify',
                    kind: t(Resource.model_name.i18n_key, scope: 'activerecord.models'),
                    what: @resources.map(&:title).join(', '))

        redirect_to refinery.admin_resources_path, status: :see_other
      end

      def create_unsuccessful invalid_resources
        @resource = invalid_resources.fetch(0) { Resource.new }

        if @resources.any?
          flash.now[:notice] = t('created', scope: 'refinery.crudify',
                      kind: t(Resource.model_name.i18n_key, scope: 'activerecord.models'),
                      what: @resources.map(&:title).join(', '))
        end

        resources_with_invalid_name = invalid_resources.collect { |r| r.errors.include?(:file_name) }

        if resources_with_invalid_name.any?
          flash.now[:alert] = t('problem_create_resources',
                        resources: resources_with_invalid_name.map(&:file_name).join(', '),
                        scope: 'refinery.admin.resources')
        end

        render action: :new
      end

      def paginate_per_page
        Resources.per_admin_page
      end

    private

      def restore_record_file_if_file_validation_fails
        if @resource.errors.include?(:file_name)
          errors = @resource.errors
          @resource = Refinery::Resource.find(@resource.id)
          errors.each { |k, v| @resource.errors.add(k, v) }
        end
      end

      def resource_params
        params.require(:resource).permit(:file)
      end

    end
  end
end
