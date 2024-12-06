Rails.application.routes.draw do
        namespace :api do
        namespace :v1 do
          resources :org_100_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_99_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_98_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_97_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_94_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_93_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_92_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_91_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_88_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_87_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_86_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_85_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_82_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_81_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_80_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_79_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_76_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_75_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_74_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_73_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_70_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_69_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_68_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_67_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_64_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_63_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_62_projects
        end
      end

        namespace :api do
        namespace :v1 do
          resources :org_61_projects
        end
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
      end

      resources :dynamic_models, only: [ :create, :index, :show ]
    end
  end
end
