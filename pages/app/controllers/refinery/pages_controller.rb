module Refinery
  class PagesController < ::ApplicationController
    include Pages::RenderOptions

    before_action :find_page
    before_action :redirect_unless_path_match, :only => [:show] if Pages.marketable_urls
    before_action :redirect_if_skip_to_first_or_link_url, :only => [:show]

    # This action is usually accessed with the root path, normally '/'
    def home
      render_with_templates?
    end

    # This action can be accessed normally, or as nested pages.
    # Assuming a page named "mission" that is a child of "about",
    # you can access the pages with the following URLs:
    #
    #   GET /pages/about
    #   GET /about
    #
    #   GET /pages/mission
    #   GET /about/mission
    #
    def show
      render_with_templates?
    end

  protected

    def should_skip_to_first_child?
      page.skip_to_first_child && first_live_child
    end

    def should_redirect_to_nested_path_url?
      !request.fullpath.match(page.nested_path)
    end

    def first_live_child
      page.children.order(:lft => :asc).live.first
    end

    def find_page(fallback_to_404 = true)
      @page ||= if home_page?
                  refinery_page.with_globalize.find_by(plugin_page_id: refinery_plugin.name)
                else
                  refinery_page.with_globalize.find_by_path_or_id(params[:path], params[:id])
                end

      @page || (error_404 if fallback_to_404)
    end

    alias_method :page, :find_page

    def refinery_page
      if current_refinery_user && current_refinery_user.authorized_plugins.include?('refinery_pages')
        Page
      else
        Page.live
      end
    end

    def redirect_if_skip_to_first_or_link_url
      if should_skip_to_first_child?
        url = refinery.url_for(first_live_child.url)
      elsif page.link_url.present?
        url = page.link_url
      end

      redirect_to(url, status: :moved_permanently) and return if url
    end

    def redirect_unless_path_match
      url = refinery.url_for(page.url)
      redirect_to url and return unless request.fullpath.match(%r(\A#{url}))
    end

  end
end
