# Encoding: utf-8
require 'friendly_id'
require 'refinery/core/base_model'
require 'refinery/pages/url'

module Refinery
  class Page < Core::BaseModel
    extend FriendlyId

    PATH_SEPARATOR = ' - '

    translates :title, :menu_title, :custom_slug, :slug, include: :seo_meta

    class Translation
      is_seo_meta
    end

    # Delegate SEO Attributes to globalize3 translation
    seo_fields = ::SeoMeta.attributes.keys.map{|a| [a, :"#{a}="]}.flatten
    delegate(*(seo_fields << { to: :translation }))

    attr_readonly :plugin_page_id

    validates :title, presence: true

    validates :custom_slug, uniqueness: true, allow_blank: true

    # Docs for acts_as_nested_set https://github.com/collectiveidea/awesome_nested_set
    # rather than :delete_all we want :destroy
    acts_as_nested_set dependent: :destroy

    # Docs for friendly_id http://github.com/norman/friendly_id
    friendly_id_options = { use: [:reserved, :globalize],
                reserved_words: %w(index new session login logout users refinery admin images) }

    if ::Refinery::Pages.scope_slug_by_parent
      friendly_id_options[:use] << :scoped
      friendly_id_options.merge!(scope: :parent)
    end

    friendly_id :custom_slug_or_title, friendly_id_options

    has_many :parts, -> {
      order(position: :asc).includes(:translations)
    }, class_name: '::Refinery::PagePart', inverse_of: :page, dependent: :destroy

    accepts_nested_attributes_for :parts, allow_destroy: true

    before_destroy :deletable?

    class << self
      # Live pages are 'allowed' to be shown in the frontend of your website.
      # By default, this is all pages that are not set as 'draft'.
      def live
        where(draft: false)
      end

      # With slugs scoped to the parent page we need to find a page by its full path.
      # For example with about/example we would need to find 'about' and then its child
      # called 'example' otherwise it may clash with another page called /example.
      def find_by_path(path)
        path = path.split('/').select(&:present?)
        page = by_slug(path.shift, :parent_id => nil).first
        page = page.children.by_slug(path.shift).first while page && path.any?

        page
      end

      # Helps to resolve the situation where you have a path and an id
      # and if the path is unfriendly then a different finder method is required
      # than find_by_path.
      def find_by_path_or_id(path, id)
        if path.present?
          if path.friendly_id?
            find_by_path(path)
          else
            find_by(id: path.to_i)
          end
        elsif id.present?
          if id.friendly_id?
            find(id)
          else
            find_by(id: id.to_i)
          end
        end
      end

      # Finds pages by their title.  This method is necessary because pages
      # are translated which means the title attribute does not exist on the
      # pages table thus requiring us to find the attribute on the translations table
      # and then join to the pages table again to return the associated record.
      def by_title(title, conditions={})
        with_globalize({
          title: title
        }.merge(conditions))
      end

      # Finds pages by their slug.  This method is necessary because pages
      # are translated which means the slug attribute does not exist on the
      # pages table thus requiring us to find the attribute on the translations table
      # and then join to the pages table again to return the associated record.
      def by_slug(slug, conditions={})
        with_globalize({
          slug: slug
        }.merge(conditions))
      end

      # Shows all pages with :show_in_menu set to true, but it also
      # rejects any page that has not been translated to the current locale.
      # This works using a query against the translated content first and then
      # using all of the page_ids we further filter against this model's table.
      def in_menu
        where(show_in_menu: true).with_globalize
      end

      # An optimised scope containing only live pages ordered for display in a menu.
      #
      def menu
        live.in_menu.with_live_localized_parents.order(arel_table[:lft]).includes(:translations)
      end

      # controls if parent is also displayed in live localized menu
      def with_live_localized_parents
        where("parent_id IS NULL OR ((SELECT count(*) FROM #{self.table_name} AS t3 INNER JOIN #{self.translation_class.table_name} AS t4 ON t3.id = t4.refinery_page_id" +
              " WHERE t3.lft < #{self.table_name}.lft AND t3.rgt > #{self.table_name}.rgt AND t3.draft = ? AND t3.show_in_menu = ? AND t4.locale = ?)" +
              " = (SELECT count(*) FROM #{self.table_name} AS t5 WHERE t5.lft < #{self.table_name}.lft AND t5.rgt > #{self.table_name}.rgt))",
              false, true, ::Globalize.locale)
      end

      # Wrap up the logic of finding the pages based on the translations table.
      def with_globalize(conditions = {})
        conditions = {locale: ::Globalize.locale.to_s}.merge(conditions)
        translations_conditions = {}
        translated_attrs = translated_attribute_names.map(&:to_s) | %w(locale)

        conditions.keys.each do |key|
          if translated_attrs.include? key.to_s
            translations_conditions["#{self.translation_class.table_name}.#{key}"] = conditions.delete(key)
          end
        end

        # A join implies readonly which we don't really want.
        where(conditions).joins(:translations).where(translations_conditions).
                                               readonly(false)
      end

      def rebuild_with_slug_nullification!
        rebuild_without_slug_nullification!
        nullify_duplicate_slugs_under_the_same_parent!
      end
      alias_method_chain :rebuild!, :slug_nullification

      protected

      def nullify_duplicate_slugs_under_the_same_parent!
        t_slug = translation_class.arel_table[:slug]
        joins(:translations).group(:locale, :parent_id, t_slug).having(t_slug.count.gt(1)).count.
        each do |(locale, parent_id, slug), count|
          by_slug(slug, locale: locale).where(parent_id: parent_id).drop(1).each do |page|
            page.slug = nil # kill the duplicate slug
            page.save # regenerate the slug
          end
        end
      end
    end

    def ancestors
      @ancestors ||= if has_ancestors
                  Refinery::Page.where('lft < ? AND rgt > ?', lft, rgt).order(lft: :asc).includes(:translations)
                else
                  []
                end
    end

    def has_ancestors
      !!parent_id
    end

    # The canonical page for this particular page.
    # Consists of:
    #   * The default locale's translated slug
    def canonical
      Globalize.with_locale(::Refinery::I18n.default_frontend_locale) { url }
    end

    # The canonical slug for this particular page.
    # This is the slug for the default frontend locale.
    def canonical_slug
      Globalize.with_locale(::Refinery::I18n.default_frontend_locale) { slug }
    end

    # Returns in cascading order: custom_slug or menu_title or title depending on
    # which attribute is first found to be present for this page.
    def custom_slug_or_title
      custom_slug.presence || menu_title.presence || title.presence
    end

    # Repositions the child page_parts that belong to this page.
    # This ensures that they are in the correct 0,1,2,3,4... etc order.
    def reposition_parts!
      reload.parts.each_with_index do |part, index|
        part.update_columns position: index
      end
    end

    # Before destroying a page we check to see if it's a deletable page or not
    # Refinery system pages are not deletable.
    def destroy
      return super if deletable?

      puts_destroy_help

      false
    end

    # If you want to destroy a page that is set to be not deletable this is the way to do it.
    def destroy!
      self.deletable = true

      destroy
    end

    # Used for the browser title to get the full path to this page
    # It automatically prints out this page title and all of it's parent page titles joined by a PATH_SEPARATOR
    def path(options = {})
      # Override default options with any supplied.
      options = {reversed: false}.merge(options)

      if has_ancestors
        # parent.path(options)
        parts = ancestors.map(&:title) <<  title
        parts.reverse! if options[:reversed]
        parts.join(PATH_SEPARATOR)
      else
        title
      end
    end

    def url
      Pages::Url.build(self)
    end

    # Returns an array with all ancestors to_param, allow with its own
    # Ex: with an About page and a Mission underneath,
    # ::Refinery::Page.find('mission').nested_url would return:
    #
    #   ['about', 'mission']
    #
    def nested_url
      [].tap do |params|
        Globalize.with_locale(Globalize.locale) do
          ancestors.each do |page|
            params << page.to_param.to_s
          end if has_ancestors
          params << to_param.to_s
        end
      end
    end


    # Returns the string version of nested_url, i.e., the path that should be
    # generated by the router
    def nested_path
      ['', nested_url].join('/')
    end

    # Returns true if this page is "published"
    def live?
      !draft?
    end

    # Return true if this page can be shown in the navigation.
    # If it's a draft or is set to not show in the menu it will return false.
    def in_menu?
      live? && show_in_menu?
    end

    def not_in_menu?
      !in_menu?
    end

    # Returns all visible sibling pages that can be rendered for the menu
    def shown_siblings
      siblings.reject(&:not_in_menu?)
    end

    def to_refinery_menu_item
      {
        id: id,
        lft: lft,
        depth: depth,
        parent_id: parent_id,
        rgt: rgt,
        title: menu_title.presence || title.presence,
        type: self.class.name,
        link_url: link_url,
        path: to_param
      }
    end

    # Accessor method to get a page part from a page.
    # Example:
    #
    #    ::Refinery::Page.first.content_for(:body)
    #
    # Will return the body page part of the first page.
    def content_for(part_title)
      part_with_title(part_title).try(:body)
    end

    # Accessor method to test whether a page part
    # exists and has content for this page.
    # Example:
    #
    #   ::Refinery::Page.first.content_for?(:body)
    #
    # Will return true if the page has a body page part and it is not blank.
    def content_for?(part_title)
      content_for(part_title).present?
    end

    # Accessor method to get a page part object from a page.
    # Example:
    #
    #    ::Refinery::Page.first.part_with_title(:body)
    #
    # Will return the Refinery::PagePart object with that title using the first page.
    def part_with_title(part_title)
      # self.parts is usually already eager loaded so we can now just grab
      # the first element matching the title we specified.
      self.parts.detect do |part|
        part.title == part_title.to_s ||
        part.title.downcase.gsub(' ', '_') == part_title.to_s.downcase.gsub(' ', '_')
      end
    end

    def any_title
      title.presence || translations.detect {|t| t.title.present? }.title
    end

  private

    # Protects generated slugs from title if they are in the list of reserved words
    # This applies mostly to plugin-generated pages.
    # This only kicks in when Refinery::Pages.marketable_urls is enabled.
    #
    # Returns the sluggified string
    def normalize_friendly_id_with_marketable_urls(slug_string)
      sluggified = slug_string.to_s.to_slug.normalize!
      if Pages.marketable_urls && self.class.friendly_id_config.reserved_words.include?(sluggified)
        sluggified << '-page'
      end
      sluggified
    end
    alias_method_chain :normalize_friendly_id, :marketable_urls

    def puts_destroy_help
      puts 'This page is not deletable. Please use .destroy! if you really want it deleted '
      puts 'set .deletable to true' unless deletable
    end

    def slug_locale
      return Globalize.locale if translation_for(Globalize.locale).try(:slug)
      #return Globalize.locale if translated_locales.include?(Globalize.locale)

      if translation_for(Refinery::I18n.default_frontend_locale).present?
        Refinery::I18n.default_frontend_locale
      else
        translations.first.locale
      end
    end
  end
end
