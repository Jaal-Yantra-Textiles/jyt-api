
Rails.application.routes.draw do
  DynamicRoute.all.each do |route|
    match route.path, to: "#{route.controller}##{route.action}", via: route.method.downcase.to_sym
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  #
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      post "login", to: "authentication#login"
      post "forgot_password", to: "passwords#forgot"
      put "reset_password", to: "passwords#reset"
      post "verify_email", to: "email_verifications#verify"
      get "auth/:provider/callback", to: "social_auths#callback"
      get "oauth_test", to: "oauth_test#index"

      post "register", to: "registrations#create"
      get "auth/:provider", to: "social_auths#passthru", as: :auth_start
      post "auth/:provider/callback", to: "social_auths#callback"
      get "auth/failure", to: "social_auths#failure"
      resources :users do
        collection do
          get :profile
          get :social_connections
        end
      end
      resources :invitations do
          get :accept, on: :member
      end
      resources :organizations do
        member do
          post :activate
          post :invite_user
          post :add_user
        end
        resources :assets
        resources :dynamic_models
      end

      resources :dynamic_models, only: [ :create, :index, :show ]
      scope "dynamic_model/:model_name" do
        get "/", to: "dynamic_model_adapter#index"
        post "/", to: "dynamic_model_adapter#create"
        get "/:id", to: "dynamic_model_adapter#show"
        put "/:id", to: "dynamic_model_adapter#update"
        delete "/:id", to: "dynamic_model_adapter#destroy"
      end
    end
  end
end
