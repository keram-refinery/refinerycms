module Refinery
  module Testing
    module ControllerMacros
      module Methods
        def get(action, parameters = nil, session = nil, flash = nil)
          process_refinery_action(action, "GET", parameters, session, flash)
        end

        # Executes a request simulating POST HTTP method and set/volley the response
        def post(action, parameters = nil, session = nil, flash = nil)
          process_refinery_action(action, "POST", parameters, session, flash)
        end

        # Executes a request simulating PUT HTTP method and set/volley the response
        def put(action, parameters = nil, session = nil, flash = nil)
          process_refinery_action(action, "PUT", parameters, session, flash)
        end

        # Executes a request simulating DELETE HTTP method and set/volley the response
        def delete(action, parameters = nil, session = nil, flash = nil)
          process_refinery_action(action, "DELETE", parameters, session, flash)
        end

        private

        def process_refinery_action(action, method = "GET", parameters = nil, session = nil, flash = nil)
          parameters ||= {}
          process(action, method, parameters.merge!(:use_route => :refinery), session, flash)
        end
      end
    end
  end
end
