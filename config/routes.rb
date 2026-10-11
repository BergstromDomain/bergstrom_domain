# config/routes.rb
Rails.application.routes.draw do
  resource  :session
  resource  :left_nav, only: [] do
    patch :toggle_visibility
    patch :toggle_section
  end
  resources :passwords, param: :token
  resources :people do
    member do
      post   :mute
      delete :unmute
    end
  end
  resources :event_types do
    member do
      post   :mute
      delete :unmute
    end
  end
  resources :social_media_platforms

  # Calendar views — declared before resources :events
  get "events/by_day",   to: "events#by_day",   as: :events_by_day
  get "events/by_week",  to: "events#by_week",  as: :events_by_week
  get "events/by_month", to: "events#by_month", as: :events_by_month

  resources :events do
    member do
      post   :mute
      delete :unmute
    end
  end

  # Sign up
  get  "sign_up", to: "registrations#new",    as: :sign_up
  post "sign_up", to: "registrations#create"

  # Contacts Management — custom-named member routes to avoid colliding with
  # the existing singular contact_path (the static "Contact Me" page below)
  resources :contacts, only: %i[index create] do
    collection { get :search }
  end
  patch  "contacts/:id/confirm", to: "contacts#confirm", as: :confirm_contact
  delete "contacts/:id",         to: "contacts#destroy",  as: :remove_contact

  # Settings
  get    "settings",                     to: "settings#show",                as: :settings
  get    "settings/edit",                to: "settings#edit",                as: :edit_settings
  patch  "settings",                     to: "settings#update"
  patch  "settings/password",            to: "settings#update_password",     as: :settings_password
  delete "settings",                     to: "settings#destroy"
  post   "settings/resend_verification", to: "settings#resend_verification", as: :resend_verification
  get    "settings/preferences",         to: "settings#preferences",         as: :preferences_settings
  patch  "settings/preferences",         to: "settings#update_preferences"
  get    "settings/chronicle",           to: "settings#chronicle_settings",  as: :chronicle_settings
  patch  "settings/chronicle",           to: "settings#update_chronicle_settings"
  get    "settings/occasions",           to: "settings#occasions_settings",  as: :occasions_settings
  patch  "settings/occasions",           to: "settings#update_occasions_settings"

  get "user_guide", to: "pages#user_guide", as: :user_guide
  resources :guide_pages, path: "guide-pages"

  # People & Events — Filter/Download/Import (Occasions' equivalent of
  # Chronicle's Filter/Download/Import Blog Posts trio)
  get "people-events/filter", to: "people_events#filter", as: :filter_people_events

  get "people-events/export",     to: "people_events_exports#index", as: :people_events_exports
  get "people-events/export/csv", to: "people_events_exports#csv",   as: :csv_people_events_exports

  get  "people-events/import",          to: "people_events_imports#new",      as: :new_people_events_import
  post "people-events/import",          to: "people_events_imports#create",   as: :people_events_imports
  get  "people-events/import/template", to: "people_events_imports#template", as: :template_people_events_imports

  # Stub pages
  get "event_tracker", to: "pages#event_tracker", as: :event_tracker
  get "chronicle",     to: "pages#chronicle",     as: :chronicle
  get "cookbook",      to: "pages#cookbook",      as: :cookbook

  # Chronicle export — declared before resources :blog_posts so these literal
  # paths win over the :id wildcard on GET /blog-posts/:id
  get "blog-posts/export",      to: "blog_exports#index", as: :blog_exports
  get "blog-posts/export/csv",  to: "blog_exports#csv",    as: :csv_blog_exports
  get "blog-posts/export/pdfs", to: "blog_exports#pdfs",   as: :pdfs_blog_exports
  get "blog-posts/export/full", to: "blog_exports#full",   as: :full_blog_exports

  get  "blog-posts/import",          to: "blog_imports#new",      as: :new_blog_import
  post "blog-posts/import",          to: "blog_imports#create",   as: :blog_imports
  get  "blog-posts/import/template", to: "blog_imports#template", as: :template_blog_imports

  # Chronicle (Blog Posts)
  resources :blog_posts, path: "blog-posts" do
    resource :like, only: %i[create destroy], controller: "likes"
    resources :comments, only: %i[create update destroy], shallow: true
    member do
      post :publish
      post :unpublish
      post :restore
      get  :pdf
    end
    collection do
      post :convert_format
      get  :deleted
      get  :filter
    end
  end
  resources :blog_categories, path: "blog-post-categories"

  # Cookbook reference data
  resources :cuisines
  resources :food_types, path: "food-types"
  resources :languages

  root "pages#home"
  get "about",      to: "pages#about"
  get "contact",    to: "pages#contact"

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
