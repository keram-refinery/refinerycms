module Refinery
  class SessionsController < Devise::SessionsController
    helper Refinery::Core::Engine.helpers
    layout 'refinery/layouts/login'

    before_action :redirect_to_registration_if_none_user
    before_action :clear_unauthenticated_flash, only: [:new]

    def create
      super
    rescue ::BCrypt::Errors::InvalidSalt, ::BCrypt::Errors::InvalidHash
      flash[:error] = t('password_encryption', scope: 'refinery.users.forgot')
      redirect_to refinery.new_refinery_user_password_path
    end

  protected

    # We don't like this alert.
    def clear_unauthenticated_flash
      if flash.keys.include?(:alert) and flash.any?{|k, v|
        ['unauthenticated', t('unauthenticated', scope: 'devise.failure')].include?(v)
      }
        flash.delete(:alert)
      end
    end

    def redirect_to_registration_if_none_user
      redirect_to(refinery.refinery_users_register_path, status: :see_other) if Refinery::Role[:refinery].users.empty?
    end

  end
end
