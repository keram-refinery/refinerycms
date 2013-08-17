module Refinery
  module Admin
    class ResourcesDialogController < ::Refinery::AdminDialogController

      def index
        @resources = Resource.paginate(page: paginate_page, per_page: paginate_per_page)
        @resource = Resource.new
      end

      def create
        begin
          @resource = Resource.create(resource_params)
        rescue Dragonfly::FunctionManager::UnableToHandle
          logger.warn($!.message)
        end

        if @resource.valid?
          json_response file: @resource.to_dialog
          index
          json_response html: { 'existing-resource-area' => render_html_to_json_string('existing_resource') }
          json_response html: render_html_to_json_string('upload_resource')
        else
          flash.now[:alert] = t('problem_create_resources',
                      resources: @resource.file_name,
                      scope: 'refinery.admin.resources')
        end
      end


    protected

      def paginate_per_page
        Resources.per_dialog_page
      end

    private

      def resource_params
        if params[:resource].present? && params[:resource][:file].present?
          { file: params[:resource][:file] }
        end
      end

    end
  end
end
