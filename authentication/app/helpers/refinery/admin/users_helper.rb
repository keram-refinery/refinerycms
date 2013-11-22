module Refinery
  module Admin
    module UsersHelper

      # sorted backend locales
      # first sorted current user locale and locales available on frontend
      # then sorted leaving
      def options_for_locale
        (((locales = Refinery::I18n.locales + [@user.locale.to_sym]) &
          Refinery::I18n.frontend_locales).sort +
          (locales - Refinery::I18n.frontend_locales).sort)
        .map do |locale|
          [lang(locale), locale]
        end
      end

    end
  end
end
