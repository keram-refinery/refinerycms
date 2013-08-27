module Refinery
  module PagesHelper

     def url_for_locale(page, locale)
      Globalize.with_locale locale do
        localized_params = params.merge(locale: locale)
        localized_params.merge!(path: page.nested_url.join('/')) unless localized_params[:path].nil?
        refinery.url_for localized_params
      end
    end

  end
end
