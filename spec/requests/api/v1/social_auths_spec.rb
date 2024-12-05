require 'swagger_helper'

RSpec.describe 'Api::V1::SocialAuths', type: :request do
  path '/api/v1/auth/{provider}/callback' do
    get 'OAuth callback endpoint' do
      tags 'Social Authentication'
      produces 'application/json'

      parameter name: :provider, in: :path, type: :string, required: true,
                description: 'OAuth provider (e.g., google_oauth2)',
                enum: [ 'google_oauth2', 'facebook' ]

      let(:auth_data) do
        OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '123456',
          info: {
            email: 'user@example.com',
            first_name: 'John',
            last_name: 'Doe'
          },
          credentials: {
            token: 'mock_token',
            expires_at: Time.now.to_i + 3600
          }
        })
      end

      before(:each) do
        OmniAuth.config.test_mode = true
        OmniAuth.config.mock_auth = {}
      end

      response '200', 'successful authentication - new user' do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 user: {
                   type: :object,
                   properties: {
                     email: { type: :string },
                     first_name: { type: :string },
                     last_name: { type: :string }
                   }
                 }
               }

        let(:provider) { 'google_oauth2' }

        before do
          OmniAuth.config.mock_auth[:google_oauth2] = auth_data
          Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
        end

        it 'creates a new user and returns proper response' do |example|
          users_before = User.count
          social_accounts_before = SocialAccount.count

          get "/api/v1/auth/#{provider}/callback"

          expect(response).to have_http_status(200)
          expect(User.count).to eq(users_before + 1)
          expect(SocialAccount.count).to eq(social_accounts_before + 1)

          data = JSON.parse(response.body)
          expect(data['token']).to be_present
          expect(data['user']['email']).to eq('user@example.com')

          user = User.last
          expect(user.email).to eq('user@example.com')
          expect(user.oauth_provider).to eq('google_oauth2')
          expect(user.oauth_token).to eq('mock_token')
          expect(user.email_verified_at).to be_present
        end
      end

      response '400', 'bad request - missing auth data' do
        let(:provider) { 'google_oauth2' }

        it 'returns proper error response' do |example|
          allow_any_instance_of(Api::V1::SocialAuthsController)
            .to receive(:callback)
            .and_raise(ActionController::ParameterMissing.new('Auth data missing'))

          get "/api/v1/auth/#{provider}/callback", headers: { 'Accept' => 'application/json' }

          expect(response).to have_http_status(400)
          data = JSON.parse(response.body)
          expect(data['error']).to include('Auth data missing')
        end
      end

      response '409', 'account exists with different provider' do
        let(:provider) { 'google_oauth2' }
        let!(:existing_user) { create(:user, email: 'user@example.com', oauth_provider: 'facebook') }

        before do
          OmniAuth.config.mock_auth[:google_oauth2] = auth_data
          Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
        end

        it 'returns conflict error' do |example|
          get "/api/v1/auth/#{provider}/callback"

          expect(response).to have_http_status(409)
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Account already exists with different provider')
        end
      end

      response '401', 'invalid credentials error' do
        let(:provider) { 'google_oauth2' }

        it 'returns unauthorized error' do |example|
          error = double(
            error: 'invalid_credentials',
            message: 'Invalid credentials'
          )

          # Skip the handle_omniauth_error call
          allow_any_instance_of(Api::V1::SocialAuthsController)
            .to receive(:handle_omniauth_error)
            .and_return(nil)

          get "/api/v1/auth/#{provider}/callback", env: {
            'omniauth.error' => error,
            'CONTENT_TYPE' => 'application/json',
            'ACCEPT' => 'application/json'
          }

          expect(response).to have_http_status(401)
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Invalid credentials provided')
        end
      end

      response '403', 'access denied by user' do
        let(:provider) { 'google_oauth2' }

        it 'returns forbidden error' do |example|
          error = double(
            error: 'access_denied',
            message: 'Access denied'
          )

          # Skip the handle_omniauth_error call
          allow_any_instance_of(Api::V1::SocialAuthsController)
            .to receive(:handle_omniauth_error)
            .and_return(nil)

          get "/api/v1/auth/#{provider}/callback", env: {
            'omniauth.error' => error,
            'CONTENT_TYPE' => 'application/json',
            'ACCEPT' => 'application/json'
          }

          expect(response).to have_http_status(403)
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Access denied by user')
        end
      end

      response '503', 'OAuth service unavailable' do
        let(:provider) { 'google_oauth2' }

        it 'returns service unavailable error' do |example|
          allow_any_instance_of(Api::V1::SocialAuthsController)
            .to receive(:callback)
            .and_raise(OAuth2::Error.new(OpenStruct.new(status: 503)))

          get "/api/v1/auth/#{provider}/callback", headers: { 'Accept' => 'application/json' }

          expect(response).to have_http_status(503)
          data = JSON.parse(response.body)
          expect(data['error']).to eq('OAuth service error')
        end
      end
    end
  end
end
