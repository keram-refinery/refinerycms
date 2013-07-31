module Refinery
  module Admin
    module PagesHelper

      # select only pages where don't belongs under current page, her including
      def parent_id_nested_set_options(current_page)
        [].tap do |pages|
          query = ::Refinery::Page.with_globalize
          if current_page.persisted?
            query = query.where.not('lft >= ? AND rgt <= ?',
                        current_page.lft, current_page.rgt)
          end

          query.includes(:translations).
                      order(:lft).each do |page|
            pages << ["#{'-' * page.depth} #{page.title}", page.id]
          end
        end
      end

      # In the admin area we use a slightly different title
      # to inform the which pages are draft or hidden pages
      def page_meta_information(page)
        meta_information = ActiveSupport::SafeBuffer.new
        meta_information << content_tag(:span, :class => 'label') do
          ::I18n.t('hidden', :scope => 'refinery.admin.pages.page')
        end unless page.show_in_menu?

        meta_information << content_tag(:span, :class => 'label notice') do
          ::I18n.t('draft', :scope => 'refinery.admin.pages.page')
        end if page.draft?

        meta_information
      end

      # We show the title from the next available locale
      # if there is no title for the current locale
      def any_page_title(page)
        page.title.presence || page.translations.detect {|t| t.title.present?}.title
      end
    end
  end
end
