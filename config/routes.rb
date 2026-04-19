# config/routes.rb
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :people
  resources :events
  resources :event_types

  root "pages#home"
  get "about",   to: "pages#about"
  get "contact", to: "pages#contact"
  get "blog-posts",  to: "pages#blog_posts", as: :blog_posts
end
