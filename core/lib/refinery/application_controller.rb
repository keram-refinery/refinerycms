module Refinery
  module ApplicationController

    def self.included(base) # Extend controller
      base.layout :layout?

      base.helper_method :xhr_json_response?,
                          :render_html_to_json_string,
                          :refinery_plugin,
                          :home_page?,
                          :local_request?,
                          :admin?,
                          :paginate_page,
                          :json_response,
                          :dialog?

      base.protect_from_forgery # See ActionController::RequestForgeryProtection

      base.send :include, Refinery::Crud # basic create, read, update and delete methods

      if Refinery::Core.rescue_not_found
        base.rescue_from ActiveRecord::RecordNotFound,
                         ::AbstractController::ActionNotFound,
                         ActionView::MissingTemplate,
                         with: :error_404
      end
    end

    def admin?
      false
    end

    def error_404(exception=nil)
      # fallback to the default 404.html page.
      file = Rails.root.join 'public', '404.html'
      file = Refinery.roots(:'refinery/core').join('public', '404.html') unless file.exist?
      render :file => file.cleanpath.to_s.gsub(%r{#{file.extname}$}, ''),
             :layout => false, :status => 404, :formats => [:html]
      return false
    end

    def error_403(exception=nil)
      file = Rails.root.join 'public', '403.html'
      file = Refinery.roots(:'refinery/core').join('public', '403.html') unless file.exist?
      render :file => file.cleanpath.to_s.gsub(%r{#{file.extname}$}, ''),
             :layout => false, :status => 403, :formats => [:html]
      return false
    end

    def home_page?
      action_name == 'home'
    end

    def local_request?
      Rails.env.development? || /(::1)|(127.0.0.1)|((192.168).*)/ === request.remote_ip
    end

    def refinery_plugin
      @refinery_plugin ||= ::Refinery::Plugins.registered.selected plugin_name_from_params
    end

    def plugin_name_from_params
      params[:controller].gsub(/\Arefinery\/(admin\/)?/, '').gsub(/_dialog\z/, '').gsub('/', '_')
    end

    def xhr_json_response?
      request.xhr? && request.format === 'application/json'
    end

    def render_html_to_json_string(partial, options={})
      options.merge({ :content_type => 'application/json', :layout => false})
      case partial
      when NilClass
        options[:template] = action_name
      when Hash
        options = options.merge(partial)
      when String
        options[:partial] = partial
      end

      tmp = formats
      self.formats = [:html]
      str = render_to_string(options)
      self.formats = tmp
      str
    end

    def paginate_page
      if params[:page].is_a?(String) || params[:page].is_a?(Fixnum)
        [params[:page].to_i, 1].max
      else
        1
      end
    end

    def json_response hash={}
      @json_response ||= { html: [] }
      @json_response[:html] << hash.delete(:html) if hash[:html]
      @json_response.merge!(hash)
    end

    JSON_LAYOUT_FOR_RESPONSE_FORMATS = ['application/json', 'text/javascript']

    def json_layout?
      request.xhr? && JSON_LAYOUT_FOR_RESPONSE_FORMATS.include?(request.format)
    end

    def layout?
      "application#{'.json' if json_layout?}"
    end

    def dialog?
      false
    end

  protected

    # use a different model for the meta information.
    def present(model)
      @meta = presenter_for(model).new(model)
    end

    def presenter_for(model, default=BasePresenter)
      return default if model.nil?

      "#{model.class.name}Presenter".constantize
    rescue NameError
      default
    end

  end
end
