module Refinery
  module Pages
    include ActiveSupport::Configurable

    config_accessor :per_dialog_page, :per_admin_page, :new_page_parts,
                    :marketable_urls, :default_parts, :main_part,
                    :use_custom_slugs, :scope_slug_by_parent,
                    :layout_template_whitelist,
                    :use_layout_templates,
                    :page_title, :types,
                    :auto_expand_admin_tree, :show_title_in_body

    self.per_dialog_page = 20
    self.per_admin_page = 20
    self.new_page_parts = false
    self.marketable_urls = true
    self.default_parts = ['Body', 'Side Body']
    self.main_part = :body
    self.use_custom_slugs = false
    self.scope_slug_by_parent = true
    self.layout_template_whitelist = ['application']

    class << self
      def layout_template_whitelist
        Array(config.layout_template_whitelist).map(&:to_s)
      end
    end

    self.use_layout_templates = false
    self.page_title = {
      :chain_page_title => false,
      :ancestors => {
        :separator => ' | ',
        :class => 'ancestors',
        :tag => 'span'
      },
      :page_title => {
        :class => nil,
        :tag => nil,
        :wrap_if_not_chained => false
      }
    }
    self.show_title_in_body = true
    self.types = Types.registered
    self.auto_expand_admin_tree = true
  end
end
