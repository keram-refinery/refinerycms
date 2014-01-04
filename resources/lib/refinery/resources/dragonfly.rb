require 'dragonfly'

module Refinery
  module Resources
    module Dragonfly

      class << self
        def configure!
          app_resources = ::Dragonfly.app(:refinery_resources)

          app_resources.configure do
            datastore :file,
              root_path: Refinery::Resources.datastore_root_path,
              server_root: Rails.root.join('public')

            url_format Refinery::Resources.dragonfly_url_format
            url_host Refinery::Resources.dragonfly_url_host
            secret Refinery.secret('dragonfly_secret_key')
            protect_from_dos_attacks Refinery::Resources.protect_from_dos_attacks

            response_header 'Content-Type', 'application/octet-stream'
            response_header 'X-Content-Type-Options', 'nosniff'
            response_header 'X-Download-Options', 'noopen'
            response_header 'Content-Disposition', Refinery::Resources.content_disposition
          end


          if Resources.s3_backend
            require 'dragonfly/s3_data_store'
            options = {
              bucket_name: Refinery::Resources.s3_bucket_name,
              access_key_id: Refinery::Resources.s3_access_key_id,
              secret_access_key: Refinery::Resources.s3_secret_access_key
            }
            options.update(region: Refinery::Resources.s3_region) if Refinery::Resources.s3_region
            app_resources.datastore :s3, options
          end

          if Resources.custom_backend?
            app_resources.datastore = Resources.custom_backend_class.new(Resources.custom_backend_opts)
          end
        end

      end

    end
  end
end
