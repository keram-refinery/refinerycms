module Refinery
  module Dashboard
    include ActiveSupport::Configurable

    config_accessor :activity_show_limit, :sidebar_actions, :records_templates

    self.activity_show_limit = 7

    self.sidebar_actions = []
    self.records_templates = []

  end
end
