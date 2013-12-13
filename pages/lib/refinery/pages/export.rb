module Refinery
  module Pages
    module Export
      class File

        def initialize pages=nil
          @pages = pages || Refinery::Page.all
        end

        def run
          @pages.each do |page|
            export_page_parts(page)
          end
        end

        private

        def export_page_parts page
          page_key = nil
          Globalize.with_locales ([:en, Refinery::I18n.default_frontend_locale] | Refinery::I18n.frontend_locales) do
            page_key ||= page.slug.underscore
          end

          Globalize.with_locales Refinery::I18n.frontend_locales do |locale|
            dir = Rails.root.join('db', 'pages', locale.to_s)
            FileUtils.mkdir_p(dir)
            page.parts.each do |part|
              part_file = "#{dir}/#{page_key}_#{part.title}.html"
              ::File.open(part_file, 'w') {|f| f.write(part.body) }
            end
          end
        end
      end
    end
  end
end
