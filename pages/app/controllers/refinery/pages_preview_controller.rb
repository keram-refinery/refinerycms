module Refinery
  class PagesPreviewController < PreviewsController
    helper Refinery::Core::Engine.helpers

    before_action :set_page

    def show
    end

    private

    def page_params
      params.require(:page).permit(
        :title, :status, :parent_id, :skip_to_first_child, :featured_image_id,
        :link_url, :show_in_menu, :browser_title, :meta_description,
        :custom_slug, parts_attributes: [:id, :title, :body, :position, :active]
      )
    end

    def set_page
      @page ||= if params[:id].present?
        Page.find(params[:id].to_s).tap { |page| page.attributes = page_params }
      else
        Page.new(page_params.except(:parts_attributes)).tap do |page|
          parts = Pages.parts.map(&:to_s)
          params[:page][:parts_attributes].each do |part_attr|
            part = page.part(part_attr[1][:title].to_sym) if parts.include?(part_attr[1][:title])
            part.attributes = part_attr[1] if part
          end if params[:page][:parts_attributes].present?
        end
      end
    end

  end
end
