require 'refinerycms-core'

require 'friendly_id'
require 'seo_meta'
require 'babosa'

ActiveSupport.on_load(:active_record) do
  require 'awesome_nested_set'
  require 'globalize3'
end


module Refinery
  autoload :PagesGenerator, 'generators/refinery/pages/pages_generator'

  module Pages
    require 'refinery/pages/engine'
    require 'refinery/pages/tab'
    require 'refinery/pages/type'
    require 'refinery/pages/types'

    # Load configuration last so that everything above is available to it.
    require 'refinery/pages/configuration'

    autoload :InstanceMethods, 'refinery/pages/instance_methods'

    class << self
      def root
        @root ||= Pathname.new(File.expand_path('../../../', __FILE__))
      end

      def valid_templates(*pattern)
        ([Rails.root] | Refinery::Plugins.registered.pathnames).map { |p|
          Dir[p.join(*pattern).to_s].flatten.map { |f|
            File.basename(f).split('.').first
          }
        }.flatten.uniq
      end

      def default_parts_for(page)
        page_types = types.find_by_name(page.view_template)
        page_types ? page_types.parts.map(&:titleize) : default_parts
      end
    end

    module Admin
      autoload :InstanceMethods, 'refinery/pages/admin/instance_methods'
    end
  end
end
