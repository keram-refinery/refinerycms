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

    # Load configuration last so that everything above is available to it.
    require 'refinery/pages/configuration'

    autoload :InstanceMethods, 'refinery/pages/instance_methods'
    autoload :Import, 'refinery/pages/import'

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
    end

    module Admin
      autoload :InstanceMethods, 'refinery/pages/admin/instance_methods'
    end
  end
end
