module Refinery
  module Admin
    class PagesController < Refinery::AdminController
      include Pages::InstanceMethods

      crudify :'refinery/page',
              include: [:translations, :children],
              paging: false


      def new
        @page = Page.new parent_id: params[:parent_id].to_i
      end

      def redirect_url
        if @page && @page.draft?
          refinery.edit_admin_page_path(@page.relative_path, frontend_locale_param)
        else
          refinery.admin_pages_path(frontend_locale_param)
        end
      end

      def update
        if @page.update_attributes(page_params)
          flash.notice = t(
            "refinery.crudify.#{@page.live? ? 'published' : 'updated'}",
            kind: t(Page.model_name.i18n_key, scope: 'activerecord.models'),
            what: @page.title
          )

          create_or_update_successful
        else
          create_or_update_unsuccessful 'edit'
        end
      end

      def children
        find_page
        render layout: false
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
        params[:page][:status] = 'live' if params[:publish].present?
        params.require(:page).permit(
          :title, :status, :parent_id, :skip_to_first_child,
          :featured_image_id, :link_url, :show_in_menu,
          :browser_title, :meta_description, :custom_slug, :page_type,
          parts_attributes: [:id, :title, :body, :position, :active]
        )
      end

      def move_allowed?(page, new_parent=nil)
        if new_parent && page.parent != new_parent && new_parent.has_child_with_same_slug?(page)
          #flash.now[:alert] = # todo
          return false
        end

        if page.plugin_page_id.present? && page.parent != new_parent
          # flash.now[:alert] = # todo
          return false
        end

        true
      end

    end
  end
end
