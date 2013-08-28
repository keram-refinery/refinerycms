module Refinery
  module ContentPagesHelper
    # Build the html for a Refinery CMS page object by creating a ContentPagePresenter. This is a
    # specialised type of ContentPresenter, so the object is then passed to render_content_presenter
    # to get its html. The options are passed to that method, so see render_content_presenter for
    # more details.
    def render_content_page(page, options = {})
      content_page_presenter = Refinery::Pages::ContentPagePresenter.new(page, page_title)
      render_content_presenter(content_page_presenter, options)
    end

    # Pass the options into a ContentPresenter object and return its html. For more
    # details see Refinery::Pages::ContentPresenter (and its subclasses).
    # This method also checks for template overrides. Any template rendered by the
    # current action may specify content_for a section using the section's id. For this
    # reason, sections should not have an ID which you would normally be using for content_for,
    # so avoid common layout names such as :header, :footer, etc.
    def render_content_presenter(content_page, options = {})
      content_page.fetch_template_overrides {|section_id| content_for(section_id)}
      content_page.to_html(options[:can_use_fallback])
    end

    # Returns url with localized path by passed locale for page
    def url_for_page_with_locale(locale, page = @page)
      Globalize.with_locale locale do
        localized_params = params.merge(locale: locale)
        localized_params.merge!(path: page.nested_url.join('/')) unless localized_params[:path].nil?
        refinery.url_for localized_params
      end
    end
  end
end
