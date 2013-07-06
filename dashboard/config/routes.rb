Refinery::Core::Engine.routes.draw do
  namespace :admin, :path => Refinery::Core.backend_route do
    root :to => 'dashboard#index'
  end
end
