module Refinery
  class PreviewsController < ::ApplicationController

    layout 'preview'

    private

    def verify_authenticity_token
      unless verified_request?
        logger.warn "[SECURITY]: CSRF detected! REFERRER: #{request.referrer} REMOTE_IP: #{request.remote_ip}"

        error_403
      end
    end

  end
end
