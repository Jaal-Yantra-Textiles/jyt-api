require 'swagger_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  path '/api/v1/users' do
    post 'Creates a user' do
      tags 'Users'
      consumes 'application/json'
      produces 'application/json'

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
              last_name: { type: :string, example: 'Doe' }
            },
            required: ['email', 'password', 'password_confirmation', 'first_name', 'last_name']
          }
        }
      }

      response '201', 'user created' do
        let(:user) do
          {
            user: {
              email: 'new@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'John',
              last_name: 'Doe'
            }
          }
        end

        schema type: :object,
          properties: {
            token: { type: :string },
            user: {
              type: :object,
              properties: {
                email: { type: :string },
                full_name: { type: :string }
              }
            }
          }

        run_test! do |response|
          expect(User.count).to eq(1)
          data = JSON.parse(response.body)
          expect(data['token']).to be_present
          expect(data['user']['email']).to eq('new@example.com')
          expect(data['user']['full_name']).to eq('John Doe')
        end
      end

      response '422', 'invalid request' do
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

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to include(
            a_string_matching(/Password is too short/),
            a_string_matching(/Email is invalid/),
            a_string_matching(/First name can't be blank/),
            a_string_matching(/Last name can't be blank/)
          )
        end
      end
    end
  end
end
