# config/routes.rb

Rails.application.routes.draw do
  # Health check endpoint for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  resources :people

  root "people#index"
end
