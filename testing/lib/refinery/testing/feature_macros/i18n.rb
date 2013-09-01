module Refinery
  module Testing
    module FeatureMacros
      module I18n

        def self.stub_frontend_locales *locales
          Refinery::I18n.stub(:frontend_locales).and_return(locales)
          Refinery::AdminController.any_instance.stub(:frontend_locales_rgxp).and_return(%r{\A(#{::Refinery::I18n.frontend_locales.join('|')})\z})
          RoutingFilter::RefineryLocales.any_instance.stub(:locales_regexp).and_return(%r{^/(#{::Refinery::I18n.frontend_locales.join('|')})(/|$)})
        end

        def self.unstub_frontend_locales
          Refinery::I18n.unstub(:frontend_locales)
          Refinery::AdminController.any_instance.unstub(:frontend_locales_rgxp)
          RoutingFilter::RefineryLocales.any_instance.unstub(:locales_regexp)
          Globalize.locale = Refinery::I18n.default_frontend_locale
          ::I18n.locale = Refinery::I18n.default_locale
        end
      end
    end
  end
end

