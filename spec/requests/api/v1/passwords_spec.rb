require 'swagger_helper'

RSpec.describe 'Api::V1::Passwords', type: :request do
  path '/api/v1/forgot_password' do
    post 'Request password reset' do
      tags 'Passwords'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.com' }
        },
        required: ['email']
      }

      response '200', 'password reset instructions sent' do
        let(:user) { create(:user) }
        let(:params) { { email: user.email } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to include('Password reset instructions sent')

          # Verify side effects
          user.reload
          expect(user.reset_password_token).to be_present
          expect(user.reset_password_sent_at).to be_present
          expect(ActionMailer::Base.deliveries.last.to).to include(user.email)
        end
      end

      response '404', 'email not found' do
        let(:params) { { email: 'wrong@example.com' } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Email not found')
        end
      end
    end
  end

  path '/api/v1/reset_password' do
    put 'Reset password' do
      tags 'Passwords'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :params, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string },
          password: { type: :string, minimum: 6 },
          password_confirmation: { type: :string, minimum: 6 }
        },
        required: ['token', 'password', 'password_confirmation']
      }

      response '200', 'password reset successfully' do
        let(:user) { create(:user) }
        let(:token) {
          user.generate_password_reset!
          user.reset_password_token
        }
        let(:params) do
          {
            token: token,
            password: 'new_password',
            password_confirmation: 'new_password'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to include('Password has been reset successfully')

          # Verify token cleared
          user.reload
          expect(user.reset_password_token).to be_nil
          expect(user.reset_password_sent_at).to be_nil
        end
      end

      response '422', 'invalid or expired token' do
        let(:user) { create(:user) }
        let(:token) {
          user.generate_password_reset!
          user.update(reset_password_sent_at: 3.hours.ago)
          user.reset_password_token
        }
        let(:params) { { token: token } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('Invalid or expired reset token')
        end
      end
    end
  end
end
