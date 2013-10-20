require 'active_support/core_ext/string'
require 'active_support/configurable'
require 'action_view/helpers/tag_helper'
require 'action_view/helpers/url_helper'

module Refinery
  module Pages
    class MenuPresenter
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::UrlHelper
      include ActiveSupport::Configurable

      config_accessor :roots, :menu_tag, :list_tag, :list_item_tag, :css, :dom_id,
                      :max_depth, :selected_css, :first_css, :last_css, :list_tag_css,
                      :link_tag_css
      self.dom_id = 'menu'
      self.css = 'menu clearfix'
      self.menu_tag = :nav
      self.list_tag = :ul
      self.list_item_tag = :li
      self.selected_css = :selected
      self.first_css = :first
      self.last_css = :last
      self.list_tag_css = 'nav'

      def roots
        config.roots.presence || collection.roots
      end

      attr_accessor :context, :collection
      delegate :output_buffer, :output_buffer=, :to => :context

      def initialize(collection, context)
        @collection = collection
        @context = context
        @request_path = context.request.path
        @request_path = @request_path.force_encoding('utf-8') if @request_path.respond_to?(:force_encoding)
        @request_path_with_decoded = [@request_path, URI.decode(@request_path)]
      end

      def to_html
        render_menu(roots) if roots.present?
      end

      private
      def render_menu(items)
        content_tag(menu_tag, :id => dom_id, :class => css, :role => 'navigation') do
          render_menu_items(items)
        end
      end

      def render_menu_items(menu_items)
        if menu_items.present?
          content_tag(list_tag, :class => list_tag_css) do
            menu_items.each_with_index.inject(ActiveSupport::SafeBuffer.new) do |buffer, (item, index)|
              @menu_item_url = context.refinery.url_for(item.url)
              buffer << render_menu_item(item, index)
            end
          end
        end
      end

      def render_menu_item_link(menu_item)
        link_to(menu_item.title, @menu_item_url, class: link_tag_css)
      end

      def render_menu_item(menu_item, index)
        content_tag(list_item_tag, :class => menu_item_css(menu_item, index)) do
          buffer = ActiveSupport::SafeBuffer.new
          buffer << render_menu_item_link(menu_item)
          buffer << render_menu_items(menu_item_children(menu_item))
          buffer
        end
      end

      # Determines whether any item underneath the supplied item is the current item according to rails.
      # Just calls selected_item? for each descendant of the supplied item
      # unless it first quickly determines that there are no descendants.
      def descendant_item_selected?(item)
        re = %r{#{@menu_item_url.gsub(/(\w+)\z/, '\1/')}}
        (0 == (@request_path_with_decoded.first =~ re) ||
          0 == (@request_path_with_decoded.last =~ re))
      end

      def selected_item_or_descendant_item_selected?(item)
        selected_item? || (item.has_children? && is_not_home? && descendant_item_selected?(item))
      end

      # Determine whether the supplied item is the currently open item according to Refinery.
      def selected_item?
        @request_path_with_decoded.include?(@menu_item_url.gsub(/(\w+)\/\z/, '\1'))
      end

      def is_not_home?
        !['/', "/#{Globalize.locale}/"].include?(@menu_item_url)
      end

      def menu_item_css(menu_item, index)
        css = []
        css << selected_css if selected_item_or_descendant_item_selected?(menu_item)
        css << first_css if index == 0
        css << last_css if index == menu_item.shown_siblings.length

        css.reject(&:blank?).presence
      end

      def menu_item_children(menu_item)
        within_max_depth?(menu_item) ? menu_item.children : []
      end

      def within_max_depth?(menu_item)
        !max_depth || menu_item.depth < max_depth
      end

    end
  end
end
