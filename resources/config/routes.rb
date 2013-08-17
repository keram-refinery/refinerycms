Refinery::Core::Engine.routes.draw do
  get '/system/resources/*dragonfly', :to => Dragonfly[:refinery_resources]

  namespace :admin, :path => Refinery::Core.backend_route do
    resources :resources, :except => :show

    get '/dialogs/resources' => 'resources_dialog#index'
    post '/dialogs/resources' => 'resources_dialog#create'
  end
end
