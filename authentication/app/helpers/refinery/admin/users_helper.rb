module Refinery
  module Admin
    module UsersHelper

      def sorted_locales
        k = I18n.locales.keys
        l = I18n.frontend_locales
        m = l.length
        n = k.length
        o = @user.locale.to_sym
        I18n.locales.sort_by {|k,v| v}.sort_by!{|locale, title|
          if locale == o
            -1 - n # user locale first
          elsif locale == I18n.default_locale
            -n # default locale second
          elsif l.include?(locale)
            m - k.rindex(locale) # next frontend locales by alphabetical order
          else
            k.rindex(locale) + n # rest by alphabetical order
          end
        }.map!(&:reverse)
      end

    end
  end
end
