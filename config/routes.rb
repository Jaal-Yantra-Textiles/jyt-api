Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  #
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      post 'login', to: 'authentication#login'
      post 'forgot_password', to: 'passwords#forgot'
      put 'reset_password', to: 'passwords#reset'
      post 'verify_email', to: 'email_verifications#verify'
      get 'auth/:provider/callback', to: 'social_auths#callback'
      get 'oauth_test', to: 'oauth_test#index'


      get 'auth/:provider', to: 'social_auths#passthru', as: :auth_start
      post 'auth/:provider/callback', to: 'social_auths#callback'
      get 'auth/failure', to: 'social_auths#failure'
      resources :users, only: [:create]
      resources :organizations
    end
  end

end
