Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Auth
  get    "/login",  to: "sessions#new",     as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :password_resets, only: [ :new, :create, :edit, :update ]

  resources :users

  resources :goals, path: "metas" do
    member { get :image }
  end
  resources :forecast_entries, path: "forecast", only: [ :index ]
  resources :one_on_ones, path: "uno_a_uno", only: [ :index, :show, :edit, :update ] do
    collection { get :entrar; get :evolucion }
    member { patch :guardar_en_historial }
  end
  resources :cliente_archivos, path: "clientes", as: "clientes", only: [ :index, :show, :create, :destroy ]

  root "dashboard#index"
end
