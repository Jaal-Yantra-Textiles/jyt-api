module Api
  module V1
    class SocialAuthsController < ApplicationController
      skip_before_action :authenticate_request
      rescue_from OAuth2::Error, with: :handle_oauth_error
      rescue_from OmniAuth::Strategies::OAuth2::CallbackError, with: :handle_callback_error
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

      def callback
        auth_data = request.env["omniauth.auth"]
        error = request.env["omniauth.error"]

        # Handle OAuth errors first
        if error.present?
          case error.error
          when "invalid_credentials"
            return render json: { error: "Invalid credentials provided" }, status: :unauthorized
          when "access_denied"
            return render json: { error: "Access denied by user" }, status: :forbidden
          else
            return handle_omniauth_error({ error: error.error, message: error.message })
          end
        end

        # Check for missing auth data
        raise ActionController::ParameterMissing.new("Auth data missing") unless auth_data

        # Process the authentication
        social_account = SocialAccount.find_or_initialize_by(
          provider: auth_data.provider,
          uid: auth_data.uid
        )

        ActiveRecord::Base.transaction do
          if social_account.new_record?
            user = create_user_from_oauth(auth_data)
            social_account.user = user
            social_account.save!
          end

          token = JwtService.encode({ user_id: social_account.user_id })
          render json: {
            token: token,
            user: UserSerializer.new(social_account.user)
          }
        end
      rescue ActiveRecord::RecordInvalid => e
        handle_validation_error(e)
      end

      def failure
        error_type = params[:error_type] || params[:message] || request.env["omniauth.error.type"]
        message = params[:message] || request.env["omniauth.error.message"] || "Unknown error"
        strategy = request.env["omniauth.strategy"]&.name
        Rails.logger.error("Failure action triggered: Type=#{error_type}, Message=#{message}, Strategy=#{strategy}, Params=#{params.inspect}")

        case error_type
        when "access_denied"
          Rails.logger.error("Access denied error triggered: Type=#{error_type}, Message=#{message}, Strategy=#{strategy}, Params=#{params.inspect}")
          render json: { error: "Access denied by user" }, status: :forbidden
        when "invalid_credentials"
          Rails.logger.error("Invalid credentials error triggered: Type=#{error_type}, Message=#{message}, Strategy=#{strategy}, Params=#{params.inspect}")
          render json: { error: "Invalid credentials provided" }, status: :unauthorized
        else
          handle_omniauth_error({ error: error_type, message: message })
        end
      end

      private

      def create_user_from_oauth(auth_data)
        existing_user = User.find_by(email: auth_data.info.email)

        if existing_user&.oauth_provider.present? && existing_user.oauth_provider != auth_data.provider
          Rails.logger.error("Raising account_exists error for email: #{auth_data.info.email}")
          error_data = { existing_provider: existing_user.oauth_provider }
          raise OmniAuth::Strategies::OAuth2::CallbackError.new(
            "account_exists",
            "Account exists with provider #{existing_user.oauth_provider}",
            error_data
          )
        end

        existing_user || create_new_user(auth_data)
      end

      def create_new_user(auth_data)
        User.create!(
          email: auth_data.info.email,
          first_name: auth_data.info.first_name,
          last_name: auth_data.info.last_name,
          oauth_provider: auth_data.provider,
          oauth_token: auth_data.credentials&.token,
          oauth_expires_at: auth_data.credentials&.expires_at&.present? ?
            Time.at(auth_data.credentials.expires_at) : nil,
          email_verified_at: Time.current # OAuth emails are pre-verified
        )
      end

      def handle_omniauth_error(error)
        Rails.logger.error("OAuth Error: #{error[:message]}")
        Rails.logger.error("OAuth Error Type: #{error[:error]}")
        status_code = case error[:error].to_s
        when "account_exists" then :conflict
        when "invalid_credentials" then :unauthorized
        when "access_denied" then :forbidden
        else :unprocessable_entity
        end

        provider = error[:error_data]&.fetch(:existing_provider, nil)
        render json: {
          error: error[:error] == "account_exists" ? "Account already exists with different provider" : error[:error],
          provider: provider
        }, status: status_code
      end

      def handle_validation_error(error)
        render json: {
          error: "Failed to create account",
          details: error.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def handle_parameter_missing(error)
              render json: {
                status: 400,
                error: error.param,
                exception: "param is missing or the value is empty or invalid: #{error.param}"
              }, status: :bad_request
            end

      def handle_callback_error(error)
        error_data = error.instance_variable_get(:@data) || {}
        handle_omniauth_error({
          error: error.error,
          message: error.message,
          parsed: error_data
        })
      end

      def handle_oauth_error(error)
        render json: { error: "OAuth service error", details: error.message }, status: :service_unavailable
      end

      def passthru
        render status: :not_found, json: { error: "Not found. Initiating OAuth flow." }
      end
    end
  end
end
