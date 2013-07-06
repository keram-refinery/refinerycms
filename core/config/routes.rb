Refinery::Core::Engine.routes.draw do
  filter(:refinery_locales)

  namespace :admin, :path => Refinery::Core.backend_route do
    get '/dialogs/links' => 'links_dialog#index'
  end

  get '/sitemap.xml' => 'sitemap#index', :defaults => { :format => 'xml' }
end
