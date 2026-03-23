# config/routes.rb
Rails.application.routes.draw do
  resources :people
  resources :events

  root "people#index"
end
