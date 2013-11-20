module Refinery
  class UserMailer < ActionMailer::Base

    def reset_password_instructions(user, token, opts={})
      @user = user
      @url = refinery.edit_refinery_user_password_url({
        :reset_password_token => token
      })

      mail(:to => user.email,
           :subject => t('subject', :scope => 'refinery.user_mailer.reset_notification'),
           :from => "\"#{Refinery::Core.site_name}\" <#{Refinery::Core.site_emails_emitter}>")
    end

  end
end
