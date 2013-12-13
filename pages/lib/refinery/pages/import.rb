module Refinery
  module Pages
    class Import

      def initialize plugin, pages, update=true
        @plugin = plugin
        @pages = pages
        @update = update
      end

      def run
        @pages.each do |key, attributes|
          page = find_page(attributes)

          if page.blank?
            page = create_page attributes
            attributes.merge!(slug: page.slug) if attributes[:slug].nil?
            update_page page, key, attributes
            update_page_parts page, key

            puts %Q(Page "#{page.title}" created.)
          else
            attributes[:id] = page.id

            if @update
              update_page page, key, attributes
              update_page_parts page, key

              puts %Q(Page "#{page.title}" updated.)
            end
          end
        end
      end

      private

      def find_page page_attrs
        if page_attrs[:plugin_page_id].present?
          Page.find_by(plugin_page_id: page_attrs[:plugin_page_id])
        else
          from = Page
          if page_attrs[:parent] && @pages[page_attrs[:parent]]
            parent = Page.find_by(id: @pages[page_attrs[:parent]][:id])
            from = parent.children if parent.present?
          end

          find_page_by_title(page_attrs[:title], from)
        end
      end

      def find_page_by_title title, from
        if title.is_a?(String)
          from::by_title(title).first
        else
          title.each do |title|
            page = from::by_title(title).first
            return page if page
          end

          nil
        end
      end

      def create_page page_attrs
        attributes = page_attrs.except(:title, :custom_slug, :parent)

        attributes[:title] = if page_attrs[:title].is_a?(String)
                      page_attrs[:title]
                    else
                      page_attrs[:title][page_attrs[:title].keys.first]
                    end

        unless page_attrs[:custom_slug].nil?
          attributes[:custom_slug] = if page_attrs[:custom_slug].is_a?(String)
                        page_attrs[:custom_slug]
                      else
                        page_attrs[:custom_slug][page_attrs[:custom_slug].keys.first]
                      end
        end

        page = Refinery::Page.create(attributes)
        page_attrs[:id] = page.id
        parent = Refinery::Page.find_by(id: @pages[page_attrs[:parent]][:id]) if page_attrs[:parent]
        page.move_to_child_of(parent) if parent

        page
      end

      def update_page page, page_key, page_attrs
        Globalize.with_locales Refinery::I18n.frontend_locales do |locale|
          attributes = page_attrs.except(:title, :custom_slug, :parent)

          attributes[:title] = if page_attrs[:title].is_a?(String)
                        page_attrs[:title]
                      elsif page_attrs[:title][locale].nil?
                        page_attrs[:title][page_attrs[:title].keys.first]
                      else
                        page_attrs[:title][locale]
                      end
          unless page_attrs[:custom_slug].nil?
            attributes[:custom_slug] = if page_attrs[:custom_slug].is_a?(String)
                          page_attrs[:custom_slug]
                        elsif page_attrs[:custom_slug][locale].nil?
                          page_attrs[:custom_slug][page_attrs[:custom_slug].keys.first]
                        else
                          page_attrs[:custom_slug][locale]
                        end
          end

          page.update(attributes)
        end
      end

      def update_page_parts page, page_key
        Globalize.with_locales Refinery::I18n.frontend_locales do |locale|
          dir = Rails.root.join('db', 'pages', locale.to_s)
          default_dir = @plugin.pathname.join('db', 'pages', locale.to_s)
          Refinery::Pages.parts.each do |part_name|
            part_data = nil
            part_file = "#{page_key}_#{part_name}.html"
            part_data = IO.read("#{dir}/#{part_file}") if File.exists?("#{dir}/#{part_file}")
            part_data = IO.read("#{default_dir}/#{part_file}") if File.exists?("#{default_dir}/#{part_file}") && part_data.nil?
            page.part(part_name).update(body: part_data)
          end if Dir.exists?(dir) || Dir.exists?(default_dir)
        end
      end
    end
  end
end
