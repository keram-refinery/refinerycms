module Refinery
  module Pages
    include ActiveSupport::Configurable

    config_accessor :per_dialog_page, :per_admin_page,
                    :marketable_urls, :default_parts, :parts,
                    :scope_slug_by_parent,
                    :layout_template_whitelist,
                    :use_layout_templates,
                    :page_title,
                    :auto_expand_admin_tree,
                    :part_to_item_property

    self.per_dialog_page = 20
    self.per_admin_page = 20
    self.marketable_urls = true
    self.parts = [:title, :perex, :body, :side_body]
    self.default_parts = [:title, :body, :side_body]
    self.scope_slug_by_parent = true
    self.layout_template_whitelist = ['application']
    self.part_to_item_property = {
      title: 'name',
      perex: 'description',
      body: 'mainContentOfPage'
    }

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

    self.auto_expand_admin_tree = true
  end
end
