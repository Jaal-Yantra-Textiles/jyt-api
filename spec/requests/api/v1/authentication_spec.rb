require 'swagger_helper'

RSpec.describe 'Api::V1::Authentication', type: :request do
  path '/api/v1/login' do
    post 'Authenticates user' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'test@example.com' },
          password: { type: :string, example: 'password123' }
        },
        required: [ 'email', 'password' ]
      }

      response '200', 'successful login' do
        let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }
        let(:credentials) { { email: 'test@example.com', password: 'password123' } }

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
          data = JSON.parse(response.body)
          expect(data['token']).to be_present
          expect(data['user']['email']).to eq(user.email)
          expect(data['user']['full_name']).to eq(user.full_name)
        end
      end

      response '401', 'invalid credentials' do
        let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }
        let(:credentials) { { email: 'test@example.com', password: 'wrong_password' } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Invalid credentials')
        end
      end
    end
  end
end
