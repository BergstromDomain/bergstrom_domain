# config/routes.rb
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :people
  resources :events
  resources :event_types

  root "people#index"
end
