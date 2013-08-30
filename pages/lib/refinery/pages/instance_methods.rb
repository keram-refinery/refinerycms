module Refinery
  module Pages
    module InstanceMethods

      def self.included(base)
        base.send :helper_method, :refinery_menu_pages
        base.send :alias_method_chain, :render, :presenters
      end

      def error_404(exception=nil)
        @page = ::Refinery::Page.with_globalize.find_by(plugin_page_id: 'pages_not_found')

        if @page.present?
          # render the application's custom 404 page with layout and meta.
          render template: '/refinery/pages/show', formats: [:html], status: 404
          return false
        else
          super
        end
      end

      # Compiles the default menu.
      def refinery_menu_pages
        Menu.new Page.menu
      end

    protected
      def render_with_presenters(*args)
        present @page unless admin? || @meta
        render_without_presenters(*args)
      end

    end
  end
end
