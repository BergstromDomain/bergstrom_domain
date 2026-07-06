# config/routes.rb
Rails.application.routes.draw do
  resource  :session
  resources :passwords, param: :token
  resources :people
  resources :event_types

  # Calendar views — declared before resources :events
  get "events/by_day",   to: "events#by_day",   as: :events_by_day
  get "events/by_week",  to: "events#by_week",  as: :events_by_week
  get "events/by_month", to: "events#by_month", as: :events_by_month

  resources :events

  # Sign up
  get  "sign_up", to: "registrations#new",    as: :sign_up
  post "sign_up", to: "registrations#create"

  # Settings
  get    "settings",                     to: "settings#show",                as: :settings
  get    "settings/edit",                to: "settings#edit",                as: :edit_settings
  patch  "settings",                     to: "settings#update"
  patch  "settings/password",            to: "settings#update_password",     as: :settings_password
  delete "settings",                     to: "settings#destroy"
  post   "settings/resend_verification", to: "settings#resend_verification", as: :resend_verification

  # Import & Export
  get "import_export", to: "pages#import_export", as: :import_export
  post "export",       to: "export#create",       as: :export
  get "user_guide",    to: "pages#user_guide",    as: :user_guide

  # Stub pages
  get "event_tracker", to: "pages#event_tracker", as: :event_tracker

  root "pages#home"
  get "about",      to: "pages#about"
  get "contact",    to: "pages#contact"
  get "blog-posts", to: "pages#blog_posts", as: :blog_posts

  namespace :system_admin do
    resources :users, only: %i[index show] do
      member do
        post :approve
        post :suspend
        post :reactivate
        post :reject
        patch :role
      end
    end
  end
end
