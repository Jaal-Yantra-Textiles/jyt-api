require 'swagger_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:regular_user) { create(:user, role: :customer) }
  let(:admin_token) { JwtService.encode(user_id: admin_user.id) }
  let(:user_token) { JwtService.encode(user_id: regular_user.id) }

  path '/api/v1/users' do
    get 'Lists all users' do
      tags 'Users'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '200', 'users found' do
        let(:Authorization) { "Bearer #{admin_token}" }

        schema type: :object,
          properties: {
            users: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  email: { type: :string },
                  full_name: { type: :string },
                  role: { type: :string }
                }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['users']).to be_an(Array)
        end
      end

      response '401', 'unauthorized' do
        let(:Authorization) { "Bearer invalid_token" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end

    post 'Creates a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: 'new@example.com' },
              password: { type: :string, example: 'password123' },
              password_confirmation: { type: :string, example: 'password123' },
              first_name: { type: :string, example: 'John' },
              last_name: { type: :string, example: 'Doe' },
              role: { type: :string, enum: [ 'customer', 'admin' ], example: 'customer' }
            },
            required: [ 'email', 'password', 'password_confirmation', 'first_name', 'last_name' ]
          }
        }
      }

      response '201', 'user created' do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:user) do
          {
            user: {
              email: 'new@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'John',
              last_name: 'Doe',
              role: 'customer'
            }
          }
        end

        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                full_name: { type: :string },
                role: { type: :string }
              }
            }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['user']['email']).to eq('new@example.com')
          expect(data['user']['full_name']).to eq('John Doe')
        end
      end

      response '422', 'invalid request' do
        let(:Authorization) { "Bearer #{admin_token}" }
        let(:user) do
          {
            user: {
              email: 'invalid_email',
              password: 'short'
            }
          }
        end

        schema type: :object,
          properties: {
            errors: {
              type: :array,
              items: { type: :string }
            }
          }

        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { "Bearer #{user_token}" }
        let(:user) { { user: attributes_for(:user) } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end

  path '/api/v1/users/profile' do
    get 'Get current user' do
      tags 'Users'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '200', 'current user retrieved' do
        let(:Authorization) { "Bearer #{user_token}" }

        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                full_name: { type: :string },
                role: { type: :string }
              }
            },
            organizations: {
              type: :object,
              properties: {
                owned: {
                  type: :array,
                  items: { type: :object }
                },
                member: {
                  type: :array,
                  items: { type: :object }
                }
              }
            }
          }

        run_test!
      end
    end
  end

  path '/api/v1/users/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Get a user' do
      tags 'Users'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '200', 'user found' do
        let(:id) { regular_user.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                full_name: { type: :string },
                role: { type: :string }
              }
            }
          }

        run_test!
      end

      response '404', 'user not found' do
        let(:id) { 0 }
        let(:Authorization) { "Bearer #{admin_token}" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end

    put 'Update a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string },
              first_name: { type: :string },
              last_name: { type: :string },
              password: { type: :string },
              password_confirmation: { type: :string }
            }
          }
        }
      }

      response '200', 'user updated' do
        let(:id) { regular_user.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:user) do
          {
            user: {
              first_name: 'Updated',
              last_name: 'Name'
            }
          }
        end

        schema type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                email: { type: :string },
                full_name: { type: :string }
              }
            }
          }

        run_test!
      end

      response '401', 'unauthorized' do
        let(:id) { admin_user.id }
        let(:Authorization) { "Bearer #{user_token}" }
        let(:user) { { user: { first_name: 'Hacker' } } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end

    delete 'Delete a user' do
      tags 'Users'
      security [ bearer_auth: [] ]

      response '200', 'user deleted' do
        let(:id) { regular_user.id }
        let(:Authorization) { "Bearer #{admin_token}" }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        run_test!
      end

      response '401', 'unauthorized' do
        let(:id) { admin_user.id }
        let(:Authorization) { "Bearer #{user_token}" }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end

  path '/api/v1/users/social_connections' do
    get 'Get user social connections' do
      tags 'Users'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response '200', 'social connections retrieved' do
        let(:Authorization) { "Bearer #{user_token}" }

        schema type: :object,
          properties: {
            connections: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  provider: { type: :string },
                  connected_at: { type: :string, format: 'date-time' },
                  expires_at: { type: :string, format: 'date-time' }
                }
              }
            }
          }

        run_test!
      end
    end
  end
end
