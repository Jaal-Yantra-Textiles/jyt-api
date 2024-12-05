require 'swagger_helper'


RSpec.describe 'API V1 Registrations', type: :request do
  path '/api/v1/register' do
    post 'Register first admin user' do
      tags 'User Registration'
      description 'Creates the first admin user in the system. Only works when no users exist.'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: 'admin@example.com' },
              password: { type: :string, example: 'password123' },
              password_confirmation: { type: :string, example: 'password123' },
              first_name: { type: :string, example: 'Admin' },
              last_name: { type: :string, example: 'Last' }
            },
            required: %w[email password password_confirmation first_name last_name]
          }
        }
      }

      response '201', 'first user created successfully' do
        let(:user) do
          {
            user: {
              email: 'admin@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'Admin',
              last_name: 'User'
            }
          }
        end

        run_test! do |response|
          perform_enqueued_jobs
          data = JSON.parse(response.body)
          expect(data['message']).to eq('First user registered successfully. Please check your email for verification.')
          expect(data['user']).to include(
            'email' => 'admin@example.com',
            'first_name' => 'Admin',
            'last_name' => 'User',
            'role' => 'admin'
          )
          expect(User.count).to eq(1)
          expect(User.first.role).to eq('admin')
          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end

      response '422', 'invalid request' do
        let(:user) do
          {
            user: {
              email: 'invalid-email',
              password: 'short',
              password_confirmation: 'nomatch',
              first_name: '',
              last_name: ''
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Registration failed')
          expect(data['details']).to include(
            'Email is invalid',
            'Password is too short (minimum is 6 characters)',
            "First name can't be blank",
            "Last name can't be blank"
          )
          expect(User.count).to eq(0)
        end
      end

      response '403', 'first user already exists' do
        let!(:existing_user) do
          User.create!(
            email: 'existing@example.com',
            password: 'password123',
            first_name: 'Existing',
            last_name: 'User',
            role: 'admin'
          )
        end

        let(:user) do
          {
            user: {
              email: 'second@example.com',
              password: 'password123',
              password_confirmation: 'password123',
              first_name: 'Second',
              last_name: 'User'
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('First user already registered')
          expect(data['message']).to eq('System already has an administrator')
          expect(User.count).to eq(1)
        end
      end
    end
  end

  # Helper method to set up Swagger docs
  def self.swagger_doc
    {
      openapi: '3.0.1',
      info: {
        title: 'User Registration API',
        version: 'v1',
        description: 'API for registering the first admin user in the system'
      },
      components: {
        schemas: {
          user: {
            type: :object,
            properties: {
              email: { type: :string },
              password: { type: :string },
              password_confirmation: { type: :string },
              first_name: { type: :string },
              last_name: { type: :string }
            },
            required: %w[email password password_confirmation first_name last_name]
          }
        }
      }
    }
  end
end
