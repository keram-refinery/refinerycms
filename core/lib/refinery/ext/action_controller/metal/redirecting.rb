require 'abstract_controller/base'

ActionController::Redirecting.module_eval do
  def redirect_to_with_json_response options = {}, response_status = {}
    if request.xhr? && request.format === Mime::JSON
      render json: { redirect_to: refinery.url_for(options) }
    elsif params['X-Requested-With'] == 'IFrame'
      json_response redirect_to: refinery.url_for(options)
    else
      redirect_to_without_json_response options, response_status
    end
  end
  alias_method_chain :redirect_to, :json_response
end
