require 'swagger_helper'

RSpec.describe 'Api::V1::SocialAuths', type: :request do
  path '/api/v1/auth/{provider}/callback' do
    get 'OAuth callback endpoint' do
      tags 'Social Authentication'
      produces 'application/json'

      parameter name: :provider, in: :path, type: :string, required: true,
                description: 'OAuth provider (e.g., google_oauth2)',
                enum: ['google_oauth2', 'facebook']

      before do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth = {}
      end

      response '400', 'bad request - missing auth data' do
        schema type: :object,
               properties: {
                 status: { type: :integer, example: 400 },
                 error: { type: :string, example: "Bad Request" },
                 exception: { type: :string, example: "param is missing or the value is empty or invalid: Auth data missing" }
               }

        let(:provider) { 'google_oauth2' }
        # Not setting up any auth mock data to trigger the 400 error

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq(400)
          expect(data['error']).to eq('Bad Request')
          expect(data['exception']).to include('Auth data missing')
        end
      end

      response '409', 'account exists with different provider' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:provider) { 'google_oauth2' }
        let!(:existing_user) { create(:user, email: 'test@example.com', oauth_provider: 'facebook') }

        before do
          OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
            provider: 'google_oauth2',
            uid: '123456',
            info: {
              email: 'test@example.com',
              first_name: 'John',
              last_name: 'Doe'
            }
          })
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('Account already exists')
        end
      end

      response '401', 'invalid credentials' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:provider) { 'google_oauth2' }

        before do
          OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('invalid_credentials')
        end
      end

      response '403', 'access denied by user' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:provider) { 'google_oauth2' }

        before do
          OmniAuth.config.mock_auth[:google_oauth2] = :access_denied
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('access_denied')
        end
      end

      response '503', 'OAuth service unavailable' do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:provider) { 'google_oauth2' }

        before do
          allow_any_instance_of(Api::V1::SocialAuthsController)
            .to receive(:callback)
            .and_raise(OAuth2::Error.new(OpenStruct.new(status: 503)))
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('OAuth service error')
        end
      end
    end
  end
end
