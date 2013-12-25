Refinery::Core::Engine.routes.draw do
  get '/system/images/*dragonfly', to: Dragonfly.app(:refinery_images)

  namespace :admin, path: Refinery::Core.backend_route do
    resources :images, except: :show

    get '/dialogs/images' => 'images_dialog#index'
    post '/dialogs/images' => 'images_dialog#create'
    get '/dialogs/image/:id' => 'image_dialog#index'
  end
end
