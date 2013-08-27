module Refinery
  module Pages

    def self.seed(plugin, pages)
      pages.each do |name, page_attributes|
        page = Refinery::Page::by_title(page_attributes[:title])

        if page.blank?
          page = Refinery::Page.create(page_attributes.except(:parent))
          page_attributes[:id] = page.id
          parent = Refinery::Page.find_by(id: pages[page_attributes[:parent]][:id]) if page_attributes[:parent]
          page.move_to_child_of(parent) if parent

          Globalize.with_locales Refinery::I18n.frontend_locales do |locale|
            page.update(title: page_attributes[:title])

            dir = Rails.root.join('db', 'pages', locale.to_s)
            default_dir = plugin.pathname.join('db', 'pages', locale.to_s)
            Refinery::Pages.parts.each do |part_name|
              part_data = nil
              part_file = "#{name}_#{part_name}.html"
              part_data = IO.read("#{dir}/#{part_file}") if File.exists?("#{dir}/#{part_file}")
              part_data = IO.read("#{default_dir}/#{part_file}") if File.exists?("#{default_dir}/#{part_file}") && part_data.nil?
              page.part(part_name).update(body: part_data) if part_data
            end if Dir.exists?(dir) || Dir.exists?(default_dir)
          end

          puts %Q(Page "#{page.title}" created.)
        else
          page_attributes[:id] = page.first.id
        end
      end
    end

  end
end
