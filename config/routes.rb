Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # SSO
  get "/sso", to: "sso#login", as: :sso_login

  # Auth
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :password_resets, only: [ :new, :create, :edit, :update ]

  get    "/auth/google/connect",  to: "google_auth#connect",    as: :google_connect
  get    "/auth/google/callback", to: "google_auth#callback",   as: :google_callback
  delete "/auth/google/disconnect", to: "google_auth#disconnect", as: :google_disconnect

  resources :users

  resources :goals, path: "metas" do
    member { get :image }
  end
  resources :forecast_entries, path: "forecast", only: [ :index ]
  resources :one_on_ones, path: "uno_a_uno", only: [ :index, :show, :edit, :update ] do
    collection { get :entrar; get :evolucion }
    member { patch :guardar_en_historial; get :reuniones_calendar }
  end
  resources :cliente_archivos, path: "clientes", as: "clientes", only: [ :index, :show, :create, :destroy ]
  resources :insights, only: [ :index ]

  root "dashboard#index"
end
