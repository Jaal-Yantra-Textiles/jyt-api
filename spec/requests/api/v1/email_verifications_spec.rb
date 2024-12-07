# spec/requests/api/v1/email_verifications_spec.rb
require 'swagger_helper'

RSpec.describe 'Api::V1::EmailVerifications', type: :request do
  path '/api/v1/verify_email' do
    post 'Verifies user email' do
      tags 'Email Verification'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :verification_params, in: :body, schema: {
        type: :object,
        properties: {
          token: { type: :string, example: 'valid_token' }
        },
        required: [ 'token' ]
      }

      response '200', 'email verified successfully' do
        let!(:user) { create(:user, email_verification_token: 'valid_token') }
        let(:verification_params) { { token: user.email_verification_token } }

        schema type: :object,
          properties: {
            message: { type: :string }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Email verified successfully')
          user.reload
          expect(user.email_verified_at).to be_present
          expect(user.email_verification_token).to be_nil
        end
      end

      response '422', 'invalid verification token' do
        let(:user) { create(:user, email_verification_token: 'valid_token') }
        let(:verification_params) { { token: 'invalid_token' } }

        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Invalid verification token')
        end
      end
    end
  end
end
