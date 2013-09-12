require 'action_controller'

module Refinery
  module Admin
    module BaseController


      def self.included(base)
        base.before_action :force_ssl!,
                           :authenticate_refinery_user!,
                           :activate_plugins,
                           :restrict_controller

        base.after_action :store_location?, only: [:index] # for redirect_back_or_default

        base.helper_method :iframe?, :group_by_date, :frontend_locale_param
      end

      def admin?
        true # we're in the admin base controller, so always true.
      end

    protected

      def force_ssl!
        redirect_to protocol: 'https' if Refinery::Core.force_ssl && !request.ssl?
      end

      def iframe?
        params['X-Requested-With'] == 'IFrame'
      end

      def group_by_date(records, date=:created_at)
        new_records = []

        records.each do |record|
          key = record[date].strftime("%Y-%m-%d")
          record_group = new_records.collect{|records| records.last if records.first == key }.flatten.compact << record
          (new_records.delete_if {|i| i.first == key}) << [key, record_group]
        end

        new_records
      end

      def activate_plugins
        authorized_plugins = current_refinery_user.authorized_plugins
        ::Refinery::Plugins.set_active(authorized_plugins)

        unless refinery_plugin
          logger.warn "Plugin accessed via '#{params[:controller]}' was not found."
          return error_404
        end

        unless authorized_plugins.include?(refinery_plugin.name)
          logger.warn "User '#{current_refinery_user.username}' tried to access plugin '#{refinery_plugin.name}' via '#{params[:controller]}' but was rejected."
          return error_403
        end
      end

      def frontend_locale_param
        Globalize.locale != current_refinery_user.frontend_locale.to_sym ? { frontend_locale: Globalize.locale } : {}
      end

    private

      def restrict_controller
        unless allow_controller? ''
          logger.warn "User '#{current_refinery_user.username}' tried to access controller '#{params[:controller]}' but was rejected."
          return error_403
        end
      end

      def allow_controller?(controller_path)
        controller_permission
      end

      def controller_permission
        true
      end

      def layout?
        "refinery/admin#{'_iframe' if iframe?}#{'.json' if json_layout?}"
      end

      # Check whether it makes sense to return the user to the last page they
      # were at instead of the default e.g. refinery_admin_pages_path
      # right now we just want to snap back to index actions and definitely not to dialogues.
      def store_location?
        store_location unless request.xhr?
      end

      # Override authorized? so that only users with the Refinery role can admin the website.
      def authorized?
        refinery_user?
      end

    end
  end
end
