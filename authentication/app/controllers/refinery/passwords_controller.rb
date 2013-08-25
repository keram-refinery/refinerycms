module Refinery
  class PasswordsController < Devise::PasswordsController
    helper Refinery::Core::Engine.helpers
    layout 'refinery/layouts/login'

    before_action :mailer_default_url_options if UserMailer.default_url_options[:host].blank?
    before_action :store_password_reset_return_to, :only => [:update]

    # Rather than overriding devise, it seems better to just apply the notice here.
    after_action :give_notice, :only => [:update]

    # GET /registrations/password/edit?reset_password_token=abcdef
    def edit
      if params[:reset_password_token]
        @refinery_user = User.new
        @refinery_user.reset_password_token = params[:reset_password_token]
        respond_with(@refinery_user)
      else
        redirect_to refinery.new_refinery_user_password_path,
                    :flash => ({ :error => t('code_invalid', :scope => 'refinery.users.reset') })
      end
    end

    # POST /registrations/password
    def create
      email = params[:refinery_user][:email] if params[:refinery_user].present? && params[:refinery_user][:email].present?
      user = User.where(:email => email).first if email.present?

      if user.present?
        user.send_reset_password_instructions

        if successfully_sent?(user)
          redirect_to refinery.login_path,
                      :notice => t('email_reset_sent', :scope => 'refinery.users.forgot')
        else
          self.new
          render :new
        end
     else

        flash.now[:error] = if email.blank?
          t('blank_email', :scope => 'refinery.users.forgot')
        else
          t('email_not_associated_with_account_html', :email => ERB::Util.html_escape(email), :scope => 'refinery.users.forgot').html_safe
        end

        self.new
        render :new
      end
    end

    protected

    def store_password_reset_return_to
      session[:refinery_user_return_to] = refinery.admin_root_path
    end

    def give_notice
      if %w(notice error alert).exclude?(flash.keys.map(&:to_s)) or @refinery_user.errors.any?
        flash[:notice] = t('successful', :scope => 'refinery.users.reset', :email => @refinery_user.email)
      end
    end

    def mailer_default_url_options
      UserMailer.default_url_options = { host: request.host_with_port }
    end

  end
end
