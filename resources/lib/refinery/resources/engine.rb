module Refinery
  module Resources
    class Engine < ::Rails::Engine
      include Refinery::Engine

      isolate_namespace Refinery
      engine_name :refinery_resources

      config.autoload_paths += %W( #{config.root}/lib )

      initializer 'attach-refinery-resources-with-dragonfly', :after => :load_config_initializers do |app|
        ::Refinery::Resources::Dragonfly.configure!
        ::Refinery::Resources::Dragonfly.attach!(app)
      end

      initializer 'register refinery_resources plugin' do
        Refinery::Plugin.register do |plugin|
          plugin.pathname = root
          plugin.name = 'refinery_resources'
          plugin.activity = { :class_name => :'refinery/resource', :title => :file_name }
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.admin_resources_path }
        end
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::Resources)
      end
    end
  end
end
