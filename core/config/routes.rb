Refinery::Core::Engine.routes.draw do
  filter :refinery_locales

  get '/sitemap.xml' => 'sitemap#index', defaults: { format: 'xml' }
end
