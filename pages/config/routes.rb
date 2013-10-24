Refinery::Core::Engine.routes.draw do
  root to: 'pages#home', via: :get

  resources :pages, only: [:show] unless Refinery::Pages.marketable_urls
  match 'preview/page', via: [:post, :patch], to: 'pages_preview#show', as: :preview_page

  namespace :admin, path: Refinery::Core.backend_route do
    get 'pages/*path/edit', to: 'pages#edit'
    patch 'pages/*path', to: 'pages#update'
    delete 'pages/*path', to: 'pages#destroy'

    resources :pages, except: :show do
      get :children, on: :member
      post :toggle_publish, on: :member
      post :update_positions, on: :collection
    end
  end
end
