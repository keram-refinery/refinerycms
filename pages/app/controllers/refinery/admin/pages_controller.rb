module Refinery
  module Admin
    class PagesController < Refinery::AdminController
      include Pages::InstanceMethods

      crudify :'refinery/page',
              :include => [:translations, :children],
              :paging => false

      def new
        @page = Page.new parent_id: params[:parent_id].to_i
      end

      def redirect_url
        if @page && @page.persisted?
          options = {}
          if Globalize.locale != I18n.default_frontend_locale
            options[:frontend_locale] = Globalize.locale
          end

          refinery.edit_admin_page_path(@page.admin_path, options)
        else
          refinery.admin_pages_path
        end
      end

      def children
        find_page
        render :layout => false
      end

    protected

      def find_page
        Globalize.with_locales([Globalize.locale, Refinery::I18n.frontend_locales].flatten.uniq) do |locale|
          @page ||= Page.find_by_path_or_id(params[:path], params[:id]) unless @page
        end

        unless @page
          raise ::ActiveRecord::RecordNotFound, "Couldn't find Refinery::Page " +
                                                "with #{(params[:path].present? ? 'path' : 'id')}=#{params[:path] || params[:id]}"
        end
      end

    private

      def page_params
        params.require(:page).permit(
          :title, :draft, :parent_id, :skip_to_first_child,
          :link_url, :show_in_menu, :browser_title, :meta_description,
          :custom_slug, :parts_attributes => [:id, :title, :body, :position, :active]
        )
      end

    end
  end
end
