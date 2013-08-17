module Refinery
  module Admin
    class PagesController < Refinery::AdminController
      include Pages::InstanceMethods

      crudify :'refinery/page',
              :include => [:translations, :children],
              :paging => false

      before_action :redirect_unless_path_match, :only => [:edit] if Pages.marketable_urls

      before_action :load_valid_templates, :only => [:edit, :new, :update, :create]

      def new
        @page = Page.new parent_id: params[:parent_id].to_i
      end

      def update
        if @page.update_attributes(page_params)
          create_or_update_successful
        else
          create_or_update_unsuccessful 'edit'
        end
      end

      def redirect_url
        if @page && @page.persisted?
          options = {}
          if Globalize.locale != I18n.default_frontend_locale
            options[:frontend_locale] = Globalize.locale
          end

          refinery.edit_admin_page_path(@page.id, options)
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
        @page ||= Page.find_by_path_or_id(params[:path], params[:id])
        unless @page
          raise ::ActiveRecord::RecordNotFound, "Couldn't find Refinery::Page " +
                                                "with #{(params[:path].present? ? 'path' : 'id')}=#{params[:path] || params[:id]}"
        end
      end

      def load_valid_templates
        @valid_layout_templates = Pages.layout_template_whitelist.map(&:to_s) &
                                  Pages.valid_templates('app', 'views', '{layouts,refinery/layouts}', '*html*')
        @valid_view_templates = Pages.valid_templates('app', 'views', '{pages,refinery/pages}', '*html*')
      end

    private

      def page_params
        params.require(:page).permit(
          :title, :draft, :parent_id, :menu_title, :skip_to_first_child,
          :link_url, :show_in_menu, :browser_title, :meta_description,
          :view_template, :layout_template,
          :parts_attributes => [:id, :title, :body, :position, :active]
        )
      end

      def redirect_unless_path_match
        url = refinery.edit_admin_page_path(@page.id)
        redirect_to url and return unless request.fullpath.match(url)
      end

    end
  end
end
