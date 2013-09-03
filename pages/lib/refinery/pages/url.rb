require 'refinery/url'

module Refinery
  module Pages
    class Url < ::Refinery::Url::Url

      class Marketable < ::Refinery::Url::Url::Marketable
        def url
          url_hash = base_url_hash.merge(path: item.nested_url, id: nil)
          with_locale_param(url_hash)
        end

        protected

        def with_locale_param(url_hash)
          locale = item.translated_locales.include?(Globalize.locale) ? Globalize.locale : item.translated_locales.first
          if locale != ::I18n.locale
            url_hash.update locale: locale
          end
          url_hash
        end
      end

      def self.build(item)
        klass = [ Localised, Marketable, Normal ].detect { |d| d.handle?(item) } || self
        klass.new(item).url
      end


    end
  end
end
