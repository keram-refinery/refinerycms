# Filters added to this controller apply to all controllers in the refinery backend.
# Likewise, all the methods added will be available for all controllers in the refinery backend.
module Refinery
  class AdminController < ::ActionController::Base
    include ::Refinery::ApplicationController
    include Refinery::Admin::BaseController
    helper ApplicationHelper
    helper Refinery::Core::Engine.helpers
  end
end
