module Refinery
  module Resources
    include ActiveSupport::Configurable

    config_accessor :dragonfly_url_format, :dragonfly_url_host,
                    :max_file_size, :per_admin_page, :per_dialog_page,
                    :s3_backend, :s3_bucket_name, :s3_region,
                    :s3_access_key_id, :s3_secret_access_key,
                    :datastore_root_path, :content_disposition,
                    :custom_backend_class, :custom_backend_opts,
                    :protect_from_dos_attacks

    self.dragonfly_url_format = '/system/resources/:job/:basename.:ext'
    self.dragonfly_url_host = ''

    self.content_disposition = 'attachment'
    self.max_file_size = 52428800
    self.per_admin_page = 20
    self.per_dialog_page = 12

    self.s3_backend = false
    self.s3_bucket_name = Refinery.secret(:s3_bucket_name)
    self.s3_region = Refinery.secret(:s3_region)
    self.s3_access_key_id = Refinery.secret(:s3_access_key_id)
    self.s3_secret_access_key = Refinery.secret(:s3_secret_access_key)

    # We have to configure these settings after Rails is available.
    # But a non-nil custom option can still be provided
    class << self
      def datastore_root_path
        config.datastore_root_path || (Rails.root.join('public', 'system', 'refinery', 'resources').to_s if Rails.root)
      end

      def s3_backend?
        config.s3_backend || Core.s3_backend
      end

      def s3_bucket_name
        config.s3_bucket_name.presence || Core.s3_bucket_name
      end

      def s3_access_key_id
        config.s3_access_key_id.presence || Core.s3_access_key_id
      end

      def s3_secret_access_key
        config.s3_secret_access_key.presence || Core.s3_secret_access_key
      end

      def s3_region
        config.s3_region.presence || Core.s3_region
      end

      def custom_backend?
        config.custom_backend_class.nil? ? Core.dragonfly_custom_backend? : config.custom_backend_class.present?
      end

      def custom_backend_class
        config.custom_backend_class.nil? ? Core.dragonfly_custom_backend_class : config.custom_backend_class.constantize
      end

      def custom_backend_opts
        config.custom_backend_opts.presence || Core.dragonfly_custom_backend_opts
      end

      def protect_from_dos_attacks
        config.protect_from_dos_attacks.presence || Core.dragonfly_protect_from_dos_attacks
      end
    end
  end
end
