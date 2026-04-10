# config/routes.rb
Rails.application.routes.draw do
  resources :people
  resources :events
  resources :event_types

  root "people#index"
end
