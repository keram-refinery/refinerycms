require 'dragonfly'

module Refinery
  module Images
    module Dragonfly

      class << self

        def configure!
          app_images = ::Dragonfly.app(:refinery_images)

          app_images.configure do
            plugin :imagemagick
            datastore :file,
              root_path: Refinery::Images.datastore_root_path,
              server_root: Rails.root.join('public')

            url_format Refinery::Images.dragonfly_url_format
            url_host Refinery::Images.dragonfly_url_host
            secret Refinery.secret('dragonfly_secret_key')
            protect_from_dos_attacks Refinery::Images.protect_from_dos_attacks
          end

          if Images.s3_backend
            require 'dragonfly/s3_data_store'
            options = {
              bucket_name: Refinery::Images.s3_bucket_name,
              access_key_id: Refinery::Images.s3_access_key_id,
              secret_access_key: Refinery::Images.s3_secret_access_key
            }
            options.update(region: Refinery::Images.s3_region) if Refinery::Images.s3_region
            app_images.datastore :s3, options
          end

          if Images.custom_backend?
            app_images.datastore = Images.custom_backend_class.new(Images.custom_backend_opts)
          end
        end

      end

    end
  end
end
