module Refinery
  module Admin
    class UsersController < Refinery::AdminController

      crudify :'refinery/user',
              :order => 'username ASC',
              :sortable => false,
              :title_attribute => 'username'

      before_action :load_available_plugins_and_roles, :only => [:new, :create, :edit, :update]

      before_action :restrict_user_editation, :only => [:edit, :update]

      def create
        # ensure that user will have access only to plugins accesible by default or max by current user
        @selected_plugin_names = params[:user][:plugins] & current_refinery_user.plugins.map(&:name)
        @selected_role_names = params[:user].delete(:roles) || []
        current_user_password = params[:user].delete(:current_user_password)

        @user = Refinery::User.new user_params

        if superuser_and_can_assign_roles? &&
                    !authenticated_current_user_with_password?(current_user_password)

          flash.now[:error] = t('your_password_is_wrong_or_missing', :scope => 'refinery.admin.users.update')
          @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }

          render :new and return
        end

        if @user.save
          @user.plugins = @selected_plugin_names

          if superuser_and_can_assign_roles?
            @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }
          else
            @user.add_role(:refinery)
          end

          redirect_to refinery.admin_users_path,
                      :status => :see_other,
                      :notice => t('created',
                        :kind => t('user', scope: 'refinery.crudify'),
                        :what => @user.username,
                        :scope => 'refinery.crudify')
        else

          if superuser_and_can_assign_roles?
            @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }
          end

          render :new
        end
      end

      def edit
        @selected_plugin_names = find_user.plugins.collect(&:name)
      end

      def update
        @user = find_user
        user_data = params[:user] || []

        @previously_selected_plugin_names = @user.plugins.collect(&:name)
        @selected_plugin_names = (user_data.delete(:plugins) || []) | @always_allowed_menu_plugins
        @previously_selected_roles = @user.roles
        @selected_role_names = user_data.delete(:roles) || []
        @selected_role_names = @user.roles.select(:title).map(&:title) unless superuser_and_can_assign_roles?
        current_user_password = user_data.delete(:current_user_password)

        if superuser_and_can_assign_roles?
          # Prevent the current user from locking themselves out of backend
          if current_refinery_user.id == @user.id && # If editing self
                      @selected_role_names.map!(&:downcase).exclude?('refinery') # And we're removing the refinery role

            flash.now[:error] = t('cannot_remove_user_from_refinery_by_self', :scope => 'refinery.admin.users.update')
            render :edit and return
          end
          @user.roles = @selected_role_names.collect { |r| Refinery::Role[r] }
        end

        if !authenticated_current_user_with_password?(current_user_password)
          flash.now[:error] = t('your_password_is_wrong_or_missing', :scope => 'refinery.admin.users.update')
          #@user.update(user_data)
          render :edit and return
        end

        if user_data[:password].blank? && user_data[:password_confirmation].blank?
          user_data.except!(:password, :password_confirmation)
        end

        if current_refinery_user.has_role?(:superuser)
          @user.plugins = @selected_plugin_names
        end

        if @user.update(user_params)
          redirect_to refinery.admin_users_path,
                      :status => :see_other,
                      :notice => t('updated',
                        :kind => t('user', scope: 'refinery.crudify'),
                        :what => @user.username,
                        :scope => 'refinery.crudify')
        else
          @user.plugins = @previously_selected_plugin_names
          @user.roles = @previously_selected_roles
          @user.save
          render :edit
        end
      end

    protected

      def find_user
        @user ||= User.friendly.find(params[:id].to_s) if params[:id].present?
      end

      def load_available_plugins_and_roles
        @user ||= Refinery::User.new
        if current_refinery_user.has_role?(:superuser) && !@user.new_record? && current_refinery_user.id != @user.id

          current_user_plugins = Hash[*current_refinery_user.plugins.collect { |plugin| [plugin.name, plugin.position] }.flatten]
          edited_user_plugins = Hash[*@user.plugins.collect { |plugin| [plugin.name, plugin.position] }.flatten]

          @available_plugins = Refinery::Plugins.registered.in_menu.collect { |a|
            { :name => a.name, :position => edited_user_plugins[a.name] || current_user_plugins[a.name] || 0 }
          }.sort_by { |a| a[:position] }
        else
          tmp = Refinery::Plugins.registered.in_menu.names
          @available_plugins = current_refinery_user.plugins.select { |a|
            { :name => a.name, :position => a.position } if tmp.include?(a.name)
          }
        end

        @selected_plugin_names = []
        @always_allowed_menu_plugins = Refinery::Plugins.always_allowed.in_menu.names
        @always_allowed_menu_plugins |= ['refinery_users'] if current_refinery_user.id == @user.id

        @available_roles = current_refinery_user.has_role?(:superuser) ? Refinery::Role.all : current_refinery_user.roles
      end

      def restrict_user_editation
        unless current_refinery_user.can_edit? find_user
          error_403 and return
        end
      end

      def authenticated_current_user_with_password? password=false
        password && current_refinery_user.valid_password?(password)
      end

      def superuser_and_can_assign_roles?
        current_refinery_user.has_role?(:superuser) && Refinery::Authentication.superuser_can_assign_roles
      end

    private

      def user_params
        params.require(:user).permit(:username, :email, :password, :password_confirmation, :locale, :full_name)
      end
    end
  end
end
