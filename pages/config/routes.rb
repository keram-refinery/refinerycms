Refinery::Core::Engine.routes.draw do
  root :to => 'pages#home', :via => :get

  resources :pages, :only => [:show] unless Refinery::Pages.marketable_urls

  namespace :admin, :path => Refinery::Core.backend_route do
    resources :pages, :except => :show do
      get :children, :on => :member
      post :update_positions, :on => :collection
    end
  end
end
