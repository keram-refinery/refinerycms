# Encoding: utf-8
require 'friendly_id'
require 'refinery/core/base_model'
require 'refinery/pages/url'
require 'refinery/globalize_finder'

module Refinery
  class Page < Core::BaseModel
    extend FriendlyId
    extend GlobalizeFinder

    PATH_SEPARATOR = ' - '
    STATES = %w(draft review live)

    translates :title, :custom_slug, :slug, :signature, :status, include: :seo_meta

    class Translation
      is_seo_meta
    end

    # Delegate SEO Attributes to globalize3 translation
    seo_fields = ::SeoMeta.attributes.keys.map{|a| [a, :"#{a}="]}.flatten
    delegate(*(seo_fields << { to: :translation }))

    attr_readonly :plugin_page_id

    validates :title, presence: true, length: { maximum: Refinery::STRING_MAX_LENGTH }

    validates :custom_slug, uniqueness: { scope: :parent_id }, allow_blank: true, length: { maximum: Refinery::STRING_MAX_LENGTH }
    validates :slug, allow_blank: true, length: { maximum: Refinery::STRING_MAX_LENGTH }
    validates :link_url, allow_blank: true, length: { maximum: Refinery::STRING_MAX_LENGTH }
    validates :status, allow_blank: true, inclusion: { in: STATES }

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

    friendly_id :title, friendly_id_options

    has_many :parts, -> {
      order(position: :asc).includes(:translations)
    }, class_name: '::Refinery::PagePart', inverse_of: :page, dependent: :destroy

    accepts_nested_attributes_for :parts, allow_destroy: true

    after_initialize do |page|
      Pages.parts.each_with_index do |page_part, index|
        page.parts << PagePart.new(
          title: page_part,
          position: index,
          active: page_part.in?(Pages.default_parts))
      end if page.new_record? && page.parts.empty?
    end

    before_destroy :deletable?

    after_update :reload_routes, if: Proc.new { |page|
      page.self_and_descendants.where(Page.arel_table[:plugin_page_id].not_eq(nil)).exists? }

    after_move :reload_routes, if: Proc.new { |page|
      page.self_and_descendants.where(Page.arel_table[:plugin_page_id].not_eq(nil)).exists? }

    after_move :update_signature
    after_save :update_signature

    class << self
      # Live pages are 'allowed' to be shown in the frontend of your website.
      # By default, this is all pages that are not set as 'draft'.
      def live
        includes(:translations).where(translation_class.arel_table[:status].eq('live')).references(:translations)
      end

      # With slugs scoped to the parent page we need to find a page by its full path.
      # For example with about/example we would need to find 'about' and then its child
      # called 'example' otherwise it may clash with another page called /example.
      def find_by_path(path)
        with_globalize(signature: OpenSSL::Digest::MD5.hexdigest(path)).first
      end

      # Helps to resolve the situation where you have a path and an id
      # and if the path is unfriendly then a different finder method is required
      # than find_by_path.
      def find_by_path_or_id(path, id)
        if (page_uid = (path.presence || id.presence).to_s).friendly_id?
          page = if (id_from_path = page_uid.split('/').last).friendly_id?
                    find_by_path page_uid
                  else
                    find id_from_path
                  end
        else
          find page_uid.to_i
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

      # Finds pages by their slug.  This method is necessary because pages
      # are translated which means the slug attribute does not exist on the
      # pages table thus requiring us to find the attribute on the translations table
      # and then join to the pages table again to return the associated record.
      def by_signature(signature, conditions={})
        with_globalize({
          signature: signature
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
        where("parent_id IS NULL OR ((SELECT COUNT(*) FROM #{self.table_name} AS t3 INNER JOIN #{self.translation_class.table_name} AS t4 ON t3.id = t4.refinery_page_id" +
              " WHERE t3.lft < #{self.table_name}.lft AND t3.rgt > #{self.table_name}.rgt AND t4.status = ? AND t3.show_in_menu = ? AND t4.locale = ?)" +
              " = (SELECT COUNT(*) FROM #{self.table_name} AS t5 WHERE t5.lft < #{self.table_name}.lft AND t5.rgt > #{self.table_name}.rgt))",
              'live', true, ::Globalize.locale)
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

    def should_generate_new_friendly_id?
      self[:slug] = custom_slug if custom_slug.present? || custom_slug != translation.custom_slug
      slug.blank?
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
        parts = ancestors.map(&:title) << title
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
            params << page.to_param
          end if ancestors

          params << to_param
        end
      end
    end

    # Returns the string version of nested_url, i.e., the path that should be
    # generated by the router
    def nested_path
      ['', nested_url].join('/')
    end

    alias_method :absolute_path, :nested_path

    def relative_path
      nested_url.join('/')
    end

    # Returns true if this page has status "live"
    def live?
      status == 'live'
    end

    # Returns true if this page  has status "draft"
    def draft?
      status == 'draft'
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
        title: title,
        type: self.class.name,
        link_url: link_url,
        path: to_param
      }
    end

    # Accessor method to get content of page part
    # Example:
    #
    #    ::Refinery::Page.first.content_for(:body)
    #
    # Will return the body of body page part of the first page.
    def content_for(part_title)
      part(part_title).body
    end

    # Accessor method to get a page part from a page.
    def part(part_title)
      self.parts.detect { |part| part.title == part_title }
    end

    def title
      return self[:title] if self[:title].present?
      translation = translations.detect {|t| t.title.present? }
      translation.title if translation
    end

    def has_child_with_same_slug?(page)
      children.includes(:translations).where(::Refinery::Page.translation_class.arel_table[:slug].in(page.translations.pluck(:slug))).exists?
    end

    def update_signature
      Globalize.with_locale Globalize.locale do
        signature = OpenSSL::Digest::MD5.hexdigest(relative_path)
        if self[:signature] != signature
          translation.update_column(:signature, signature) unless translation.new_record?
          self[:signature] = signature
          children.each do |child|
            child.update_signature
          end unless new_record?
        end
      end
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

    def reload_routes
      Rails.application.routes_reloader.reload!
    end

  end
end
