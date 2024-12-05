module Api
  module V1
    class EmailVerificationsController < ApplicationController
      skip_before_action :authenticate_request, only: [:verify]

      def verify
        user = User.find_by(email_verification_token: params[:token])

        if user&.verify_email!
          render json: { message: 'Email verified successfully' }
        else
          render json: { error: 'Invalid verification token' }, status: :unprocessable_entity
        end
      end
    end
  end
end
