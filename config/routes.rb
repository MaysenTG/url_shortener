Rails.application.routes.draw do
  get '/urls', to: redirect('/')
  get '/url/:url/edit', to: redirect('/')
  
  resources :urls
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "urls#new"
  
  get '/:shortened_url', to: 'urls#redirect'
  get '/:shortened_url/clicks', to: 'urls#get_clicks', as: 'url_clicks'
  get '/urls/:shortened_url', to: 'urls#show', as: 'url_show'
  
  post '/search_url', to: 'urls#search_url', as: 'search_url'
  
  match '*unmatched', to: redirect('/'), via: :all
end
