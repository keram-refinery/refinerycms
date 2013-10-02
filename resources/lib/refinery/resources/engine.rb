module Refinery
  module Resources
    class Engine < ::Rails::Engine
      extend Refinery::Engine

      isolate_namespace Refinery
      engine_name :refinery_resources

      config.autoload_paths += %W( #{config.root}/lib )

      initializer 'attach-refinery-resources-with-dragonfly', :after => :load_config_initializers do |app|
        ::Refinery::Resources::Dragonfly.configure!
        ::Refinery::Resources::Dragonfly.attach!(app)
      end

      initializer 'register resources plugin' do
        Refinery::Plugin.register do |plugin|
          plugin.pathname = root
          plugin.name = 'resources'
          plugin.activity = { :class_name => :'refinery/resource', :title => :file_name }
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.admin_resources_path }
        end

        Refinery::Dashboard.sidebar_actions << '/refinery/admin/resources/dashboard_actions'

        Refinery::Links.tabs.push('resources') if defined? Refinery::Links
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::Resources)
      end
    end
  end
end
