module Refinery
  module Testing
    module FeatureMacros
      module Authentication

        def refinery_login_with(factory)
          let!(:logged_in_user) do
            if Refinery::User.any?
              Refinery::User.first
            else
              FactoryGirl.create(factory)
            end
          end

          before do
            login_as logged_in_user, :scope => :refinery_user
          end
        end

      end
    end
  end
end
