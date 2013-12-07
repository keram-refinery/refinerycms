module Refinery
  module Admin
    class UsersController < Refinery::AdminController

      crudify :'refinery/user',
              order: 'username ASC',
              sortable: false,
              title_attribute: 'username'

      before_action :available_plugins_for_new, :available_roles_for_new,
                    only: [:new, :create]
      before_action :find_user, only: [:edit, :update, :destroy]
      before_action :restrict_user_editation, only: [:edit, :update, :destroy]

      before_action :available_plugins, :available_roles,
                     :restrict_user_editation, only: [:edit, :update]

      def new
        @user = Refinery::User.new
        @selected_plugin_names = current_refinery_user.plugins.map(&:name)
      end

      def create
        @user = Refinery::User.new user_params
        @selected_plugin_names = (params[:user][:plugins] & current_refinery_user.plugins.map(&:name)) || []
        @selected_role_names = params[:user][:roles] || []

        unless authenticated_current_user_with_password?
          flash.now[:error] = t('your_password_is_wrong_or_missing', scope: 'refinery.admin.users.update')
          @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }
          render :new and return
        end

        if @user.save
          create_successful
        else
          create_failed
        end
      end

      def edit
        @selected_plugin_names = @user.plugins.map(&:name)
      end

      def update
        # Store what the user selected.
        @selected_role_names = user_can_assign_roles? ?
                                (params[:user].delete(:roles) || []) :
                                @user.roles.pluck(:title)
        @selected_plugin_names = params[:user][:plugins] & current_refinery_user.plugins.map(&:name)
        user_data = params_with_excluded_password_assignment_when_blank

        if user_is_locking_themselves_out?
          flash.now[:error] = t('lockout_prevented', scope: 'refinery.admin.users.update')
          render :edit and return
        end

        store_user_memento

        @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }

        unless authenticated_current_user_with_password?
          flash.now[:error] = t('your_password_is_wrong_or_missing', scope: 'refinery.admin.users.update')
          render :edit and return
        end

        if @user.update_attributes user_data
          update_successful
        else
          update_failed
        end
      end

      protected

      def create_successful
        @user.plugins = @selected_plugin_names

        # if the user is a superuser and can assign roles according to this site's
        # settings then the roles are set with the POST data.
        if user_can_assign_roles?
          @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }
        else
          @user.add_role :refinery
        end

        redirect_to refinery.admin_users_path,
                    status: :see_other,
                    notice: t('created',
                      kind: t(Refinery::User.model_name.i18n_key, scope: 'activerecord.models'),
                      what: @user.username,
                      scope: 'refinery.crudify')
      end

      def create_failed
        render :new
      end

      def update_successful
        redirect_to refinery.admin_users_path,
                    status: :see_other,
                    notice: t('updated',
                      kind: t(Refinery::User.model_name.i18n_key, scope: 'activerecord.models'),
                      what: @user.username,
                      scope: 'refinery.crudify')
      end

      def update_failed
        user_memento_rollback!

        render :edit
      end

      def find_user
        @user ||= User.friendly.find(params[:id].to_s) if params[:id].present?
        @user || error_404 and return
      end

      private

      def available_plugins
        current_user_plugins = Hash[*current_refinery_user.plugins.collect { |plugin| [plugin.name, plugin.position] }.flatten]
        edited_user_plugins = Hash[*@user.plugins.collect { |plugin| [plugin.name, plugin.position] }.flatten]

        @available_plugins = Refinery::Plugins.registered.in_menu.collect { |a|
          { name: a.name, position: edited_user_plugins[a.name] || current_user_plugins[a.name] || 0 }
        }.sort_by { |a| a[:position] }
      end

      def available_roles
        @available_roles = Refinery::Role.all
      end

      def available_plugins_for_new
        @available_plugins = current_refinery_user.plugins.collect { |a| { name: a.name, position: a.position } }
      end

      def available_roles_for_new
        @available_roles = Refinery::Role.all
      end

      def restrict_user_editation
        unless current_refinery_user.can_edit? @user
          error_403 and return
        end
      end

      def params_with_excluded_password_assignment_when_blank
        user_params.tap do |a|
          if a[:password].blank? && a[:password_confirmation].blank?
            a.delete(:password)
            a.delete(:password_confirmation)
          end
        end
      end

      def user_can_assign_roles?
        Refinery::Authentication.superuser_can_assign_roles && current_refinery_user.has_role?(:superuser)
      end

      def user_is_locking_themselves_out?
        return false if current_refinery_user.id != @user.id || @selected_plugin_names.blank?
        @selected_plugin_names.exclude?('users') || # removing user plugin access
          @selected_role_names.exclude?('refinery') # Or we're removing the refinery role
      end

      def store_user_memento
        # Store the current plugins and roles for this user.
        @previously_selected_plugin_names = @user.plugins.map(&:name)
        @previously_selected_roles = @user.roles
      end

      def user_memento_rollback!
        @user.plugins = @previously_selected_plugin_names
        @user.roles = @previously_selected_roles
        @user.save
      end

      def authenticated_current_user_with_password?
        current_refinery_user.valid_password?(params[:user].delete(:current_user_password))
      end

      def user_params
        params.require(:user).permit(
          :username, :email, :about, :image_id,
          :password, :password_confirmation,
          :locale, :full_name)
      end
    end
  end
end
