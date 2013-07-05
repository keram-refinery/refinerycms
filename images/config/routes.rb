Refinery::Core::Engine.routes.draw do
  get '/system/images/*dragonfly', :to => Dragonfly[:refinery_images]

  namespace :admin, :path => Refinery::Core.backend_route do
    resources :images, :except => :show

    get '/dialogs/images' => 'images_dialog#index'
  end
end
