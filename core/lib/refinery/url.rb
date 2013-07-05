module Refinery
  module Url

    class Url

      class Localised < Url

        def self.handle? item
          item.link_url.present?
        end

        def url
          current_url = item.link_url

          if current_url =~ %r{^/} &&
            Globalize.locale != Refinery::I18n.default_frontend_locale
            current_url = "/#{Globalize.locale}#{current_url}"
          end

          current_url
        end
      end

      class Marketable < Url
        def self.handle? item
          Refinery::Pages.marketable_urls
        end

        def url
          url_hash = base_url_hash.merge(:path => item.parents.map(&:path) << item.path, :id => nil)
          with_locale_param(url_hash)
        end
      end

      class Normal < Url
        def self.handle? item
          item.to_param.present?
        end

        def url
          url_hash = base_url_hash.merge(:path => nil, :id => item.to_param)
          with_locale_param(url_hash)
        end
      end

      def self.build(item)
        klass = [ Localised, Marketable, Normal ].detect { |d| d.handle?(item) } || self
        klass.new(item).url
      end

      def initialize(item)
        @item = item
      end

      def url
        raise NotImplementedError
      end

      private

      attr_reader :item

      def with_locale_param(url_hash)
        if (locale = Globalize.locale) != ::I18n.locale
          url_hash.update :locale => locale
        end
        url_hash
      end

      def base_url_hash
        { :controller => '/refinery/pages', :action => 'show', :only_path => true }
      end
    end

  end
end