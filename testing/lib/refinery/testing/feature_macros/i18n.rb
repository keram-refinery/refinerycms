module Refinery
  module Testing
    module FeatureMacros
      module I18n

        def self.stub_frontend_locales *locales
          Refinery::I18n.stub(:frontend_locales).and_return(locales)
          Refinery::I18n.stub(:'frontend_locales_keys').and_return(locales.map(&:to_s))
          RoutingFilter::RefineryLocales.any_instance.stub(:locales_regexp).and_return(%r{^/(#{::Refinery::I18n.frontend_locales.join('|')})(/|$)})
          Refinery::Page.where.not(plugin_page_id: nil).each do |page|
            Globalize.with_locales Refinery::I18n.frontend_locales do |locale|
              page.update(title: page.title)
            end
          end
          Rails.application.routes_reloader.reload!
        end

        def self.unstub_frontend_locales
          Refinery::I18n.unstub(:frontend_locales)
          Refinery::I18n.unstub(:frontend_locales_keys)
          RoutingFilter::RefineryLocales.any_instance.unstub(:locales_regexp)
          Globalize.locale = Refinery::I18n.default_frontend_locale
          ::I18n.locale = Refinery::I18n.default_locale
          Rails.application.routes_reloader.reload!
        end
      end
    end
  end
end

