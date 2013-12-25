module Refinery
  module Images
    class Engine < ::Rails::Engine
      extend Refinery::Engine

      isolate_namespace Refinery
      engine_name :refinery_images

      config.autoload_paths += %W( #{config.root}/lib )

      initializer 'attach-refinery-images-with-dragonfly', after: :load_config_initializers do |app|
        ::Refinery::Images::Dragonfly.configure!
      end

      initializer 'register images plugin' do
        Refinery::Plugin.register do |plugin|
          plugin.pathname = root
          plugin.name = 'images'
          plugin.activity = {
            class_name: :'refinery/image',
            title: :image_name
          }
          plugin.url = proc { Refinery::Core::Engine.routes.url_helpers.admin_images_path }
        end

        Refinery::Dashboard.sidebar_actions << '/refinery/admin/images/dashboard_actions'
      end

      config.after_initialize do
        Refinery.register_extension(Refinery::Images)
      end
    end
  end
end
