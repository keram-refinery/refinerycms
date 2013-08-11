module Refinery
  module Admin
    class ResourcesController < ::Refinery::AdminController

      crudify :'refinery/resource',
              :sortable => false

      def new
        @resource = Resource.new
      end

      def create
        @resources = []
        invalid_resources = []

        if params[:resource].present? && params[:resource][:file].is_a?(Array)
          params[:resource][:file].each do |resource|
            begin
              @resource = Resource.create({:file => resource}.merge(resource_params))

              if @resource.valid?
                @resources << @resource
              else
                invalid_resources << @resource
              end
            rescue Dragonfly::FunctionManager::UnableToHandle
              logger.warn($!.message)
              invalid_resources << @resource.file_name
            end
          end
        end

        if invalid_resources.empty? and @resources.any?
          redirect_to refinery.admin_resources_path
        else
          create_unsuccessful invalid_resources
        end
      end

      def update
        attributes_before_assignment = @resource.attributes
        @resource.attributes = params.require(:resource).permit(:file)

        if @resource.valid? && @resource.save
          flash.notice = t(
            'refinery.crudify.updated',
            :kind => t('resource', scope: 'refinery.crudify'),
            :what => "#{@resource.title}"
          )

          redirect_back_or_default refinery.admin_resources_path
        else
          render :action => 'edit'
        end
      end

    protected

      def create_unsuccessful invalid_resources
        @resource = invalid_resources.fetch(0) { Resource.new }

        if @resources.any?
          flash.notice = t('created', :scope => 'refinery.crudify',
                      :kind => t('resource', scope: 'refinery.crudify'), :what => "#{@resources.map(&:title).join(", ")}")
        end

        unless invalid_resources.empty? ||
                    (invalid_resources.size == 1 && @resource.errors.keys.first == :file_name)
          flash.alert = t('problem_create_resources',
                         resources: invalid_resources.map(&:file_name).join(', '),
                        scope: 'refinery.admin.resources')
        end

        render :action => 'new'
      end

      def paginate_per_page
        Resources.per_admin_page
      end

    private

      def resource_params
        params[:resource].except(:file)
      end

    end
  end
end
