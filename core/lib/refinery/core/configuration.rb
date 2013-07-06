module Refinery
  module Core
    include ActiveSupport::Configurable

    config_accessor :rescue_not_found, :s3_backend, :base_cache_key, :site_name,
                    :google_analytics_page_code, :authenticity_token_on_frontend,
                    :dragonfly_secret,
                    :javascripts, :I18n_javascripts, :stylesheets,
                    :admin_javascripts, :admin_I18n_javascripts, :admin_stylesheets,
                    :s3_bucket_name, :s3_region, :s3_access_key_id,
                    :s3_secret_access_key, :force_ssl, :backend_route,
                    :dragonfly_custom_backend_class, :dragonfly_custom_backend_opts

    self.rescue_not_found = false
    self.s3_backend = false
    self.base_cache_key = :refinery
    self.site_name = 'Site Name'
    self.google_analytics_page_code = 'UA-xxxxxx-x'
    self.authenticity_token_on_frontend = false
    self.dragonfly_secret = Array.new(24) { rand(256) }.pack('C*').unpack('H*').first
    self.javascripts = []
    self.I18n_javascripts = {}
    self.stylesheets = []
    self.admin_javascripts = []
    self.admin_I18n_javascripts = {}
    self.admin_stylesheets = []
    self.s3_bucket_name = ENV['S3_BUCKET']
    self.s3_region = ENV['S3_REGION']
    self.s3_access_key_id = ENV['S3_KEY']
    self.s3_secret_access_key = ENV['S3_SECRET']
    self.force_ssl = false
    self.backend_route = 'refinery'
    self.dragonfly_custom_backend_class = ''
    self.dragonfly_custom_backend_opts = {}

    def config.register_javascript(name)
      self.javascripts |= Array(name)
    end

    def config.register_I18n_javascript(locale, name)
      self.I18n_javascripts[locale] ||= []
      self.I18n_javascripts[locale] |= Array(name)
    end

    def config.register_stylesheet(*args)
      self.stylesheets |= Array(Stylesheet.new(*args))
    end

    def config.register_admin_javascript(name)
      self.admin_javascripts |= Array(name)
    end

    def config.register_admin_I18n_javascript(locale, name)
      self.admin_I18n_javascripts[locale] ||= []
      self.admin_I18n_javascripts[locale] |= Array(name)
    end

    def config.register_admin_stylesheet(*args)
      self.admin_stylesheets |= Array(Stylesheet.new(*args))
    end

    class << self

      def dragonfly_custom_backend?
        config.dragonfly_custom_backend_class.present?
      end

      def dragonfly_custom_backend_class
        config.dragonfly_custom_backend_class.constantize if dragonfly_custom_backend?
      end

      def site_name
        ::I18n.t('site_name', :scope => 'refinery.core.config', :default => config.site_name)
      end
    end

    # wrapper for stylesheet registration
    class Stylesheet
      attr_reader :options, :path
      def initialize(*args)
        @options = args.extract_options!
        @path = args.first if args.first
      end
    end

  end
end
