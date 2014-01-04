module Refinery
  module Core
    include ActiveSupport::Configurable

    config_accessor :rescue_not_found, :base_cache_key,
                    :site_name, :site_emails_emitter, :site_emails_receiver,
                    :google_analytics_page_code, :authenticity_token_on_frontend,
                    :javascripts, :I18n_javascripts, :stylesheets, :turbolinks_on_frontend,
                    :admin_javascripts, :admin_I18n_javascripts, :admin_stylesheets,
                    :s3_backend, :s3_bucket_name, :s3_region, :s3_access_key_id,
                    :s3_secret_access_key, :force_ssl, :backend_route,
                    :dragonfly_custom_backend_class, :dragonfly_custom_backend_opts,
                    :dragonfly_protect_from_dos_attacks,
                    :extern_javascripts, :admin_extern_javascripts,
                    :wysiwyg_editor

    self.rescue_not_found = false
    self.base_cache_key = :refinery
    self.site_name = 'Site Name'
    self.site_emails_emitter = 'no-reply@localhost'
    self.site_emails_receiver = 'info@localhost'
    self.google_analytics_page_code = 'UA-xxxxxx-x'
    self.authenticity_token_on_frontend = false
    self.javascripts = []
    self.I18n_javascripts = {}
    self.extern_javascripts = []
    self.turbolinks_on_frontend = true
    self.stylesheets = []
    self.admin_javascripts = []
    self.admin_I18n_javascripts = {}
    self.admin_extern_javascripts = []
    self.admin_stylesheets = []
    self.s3_backend = false
    self.s3_bucket_name = Refinery.secret('s3_bucket_name')
    self.s3_region = Refinery.secret('s3_region')
    self.s3_access_key_id = Refinery.secret('s3_access_key_id')
    self.s3_secret_access_key = Refinery.secret('s3_secret_access_key')
    self.force_ssl = false
    self.backend_route = 'refinery'
    self.dragonfly_custom_backend_class = ''
    self.dragonfly_custom_backend_opts = {}
    self.dragonfly_protect_from_dos_attacks = true

    def config.register_javascript(name)
      self.javascripts |= Array(name)
    end

    def config.register_I18n_javascript(locale, name)
      self.I18n_javascripts[locale] ||= []
      self.I18n_javascripts[locale] |= Array(name)
    end

    def config.register_extern_javascript(options)
      self.extern_javascripts << options
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

    def config.register_extern_javascript(options)
      self.admin_extern_javascripts << options
    end

    def config.register_admin_stylesheet(*args)
      self.admin_stylesheets |= Array(Stylesheet.new(*args))
    end

    class << self
      def backend_route
        # prevent / at the start.
        config.backend_route.to_s.gsub(%r{\A/}, '')
      end

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
