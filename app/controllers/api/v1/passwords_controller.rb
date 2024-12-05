module Api
  module V1
    class PasswordsController < ApplicationController
      skip_before_action :authenticate_request

      def forgot
        user = User.find_by(email: params[:email])
        if user
          user.generate_password_reset!
          AuthMailer.with(user: user).password_reset.deliver_later
          render json: { message: 'Password reset instructions sent to your email' }
        else
          render json: { error: 'Email not found' }, status: :not_found
        end
      end

      def reset
        user = User.find_by(reset_password_token: params[:token])

        if user&.reset_password_sent_at && !user.password_reset_expired?
          if user.update(password_params)
            user.update(reset_password_token: nil, reset_password_sent_at: nil)
            render json: { message: 'Password has been reset successfully' }
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Invalid or expired reset token' }, status: :unprocessable_entity
        end
      end

      private

      def password_params
        params.permit(:password, :password_confirmation)
      end
    end
  end
end
