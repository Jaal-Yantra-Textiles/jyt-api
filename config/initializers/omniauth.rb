# config/initializers/omniauth.rb
#
OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.allowed_request_methods << :get if Rails.env.test? || Rails.env.development?

Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
      config.path_prefix = "/api/v1/auth"
      config.failure_raise_out_environments = []
    end
  # Google OAuth2
  provider :google_oauth2,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      {
        scope: "email,profile",
        prompt: "select_account",
        access_type: "offline",
        skip_jwt: true
      }

  # Facebook
  provider :facebook,
           ENV["FACEBOOK_APP_ID"],
           ENV["FACEBOOK_APP_SECRET"],
           {
             scope: "email,public_profile",
             info_fields: "email,first_name,last_name,picture"
           }
    # Optional: Enable detailed OAuth debugging
    # OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
    OmniAuth.config.on_failure = Proc.new { |env|
      error_type = env["omniauth.error.type"]
      strategy = env["omniauth.strategy"]&.name
      message = env["omniauth.error.message"]

      Rails.logger.error("OmniAuth failure triggered: Type=#{error_type}, Message=#{message}, Strategy=#{strategy}")

      Api::V1::SocialAuthsController.action(:failure).call(env)
    }
end
