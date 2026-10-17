Rails.application.routes.draw do
  get "/contact" => "contact#index", as: "contact"
  post "/contact" => "contact#send_mail", as: "send_contact"

  resources :urls, only: %i[new create] do
    get :validate, on: :collection
  end

  root "urls#new"

  get "/urls/:shortened_url", to: "urls#show", as: "url_show"
  get "/:shortened_url/clicks", to: "urls#get_clicks", as: "url_clicks"
  post "/search_url", to: "urls#search_url", as: "search_url"

  get "/:shortened_url", to: "urls#redirect"

  match "*unmatched", to: redirect("/"), via: :all
end
