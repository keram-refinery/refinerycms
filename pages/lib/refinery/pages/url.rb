require 'refinery/url'

module Refinery
  module Pages
    class Url < ::Refinery::Url::Url

      class Marketable < ::Refinery::Url::Url::Marketable
        def url
          url_hash = base_url_hash.merge(:path => item.nested_url, :id => nil)
          with_locale_param(url_hash)
        end
      end

      def self.build(item)
        klass = [ Localised, Marketable, Normal ].detect { |d| d.handle?(item) } || self
        klass.new(item).url
      end

    end
  end
end
