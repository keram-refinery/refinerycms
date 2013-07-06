module Refinery
  module Dashboard
    class Engine < ::Rails::Engine
      extend Refinery::Engine

      isolate_namespace Refinery
      engine_name :refinery_dashboard

      config.autoload_paths += %W( #{config.root}/lib )

      initializer 'register refinery_dashboard plugin' do
        Refinery::Plugin.register do |plugin|
          plugin.pathname = root
          plugin.name = 'refinery_dashboard'
          plugin.always_allow_access = true
          plugin.dashboard = true
          plugin.position = 1
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.admin_root_path }
        end
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::Dashboard)
      end
    end
  end
end
