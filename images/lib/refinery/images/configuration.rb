module Refinery
  module Images
    include ActiveSupport::Configurable

    config_accessor :dragonfly_url_format, :dragonfly_url_host,
                    :max_image_size, :per_dialog_page, :per_admin_page,
                    :user_image_sizes,
                    :image_views, :preferred_image_view, :datastore_root_path,
                    :s3_backend, :s3_bucket_name, :s3_region,
                    :s3_access_key_id, :s3_secret_access_key,
                    :whitelisted_mime_types,
                    :custom_backend_class, :custom_backend_opts,
                    :protect_from_dos_attacks

    # If you decide to trust file extensions replace :ext below with :format
    self.dragonfly_url_format = '/system/images/:job/:basename.:ext'
    self.dragonfly_url_host = ''

    self.max_image_size = 5242880
    self.per_dialog_page = 20
    self.per_admin_page = 20
    self.user_image_sizes = {
      :small => '110x110>',
      :medium => '225x255>',
      :large => '450x450>'
    }

    self.whitelisted_mime_types = %w[image/jpeg image/png image/gif image/tiff]

    self.image_views = [:grid, :list]
    self.preferred_image_view = :grid

    self.s3_backend = false
    self.s3_bucket_name = Refinery.secret('s3_bucket_name', false)
    self.s3_region = Refinery.secret('s3_region', false)
    self.s3_access_key_id = Refinery.secret('s3_access_key_id', false)
    self.s3_secret_access_key = Refinery.secret('s3_secret_access_key', false)

    # We have to configure these settings after Rails is available.
    # But a non-nil custom option can still be provided
    class << self
      def datastore_root_path
        config.datastore_root_path || (Rails.root.join('public', 'system', 'refinery', 'images').to_s if Rails.root)
      end

      def s3_backend?
        config.s3_backend || Core.s3_backend
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
