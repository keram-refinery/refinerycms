module Refinery
  module Testing
    module FeatureMacros
      module Authentication

        def refinery_login_with(factory)
          Refinery::User.delete_all

          let!(:logged_in_user) do
            FactoryGirl.create(factory)
          end

          before do
            login_as logged_in_user, :scope => :refinery_user
          end
        end

      end
    end
  end
end
