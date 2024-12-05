module Api
  module V1
    class RegistrationsController < ApplicationController
      skip_before_action :authenticate_request, only: [ :create ]

      def create
        return render_first_user_exists unless first_user_registration?

        @user = User.new(user_params)
        @user.role = :admin # First user is always admin

        if @user.save
            # Generate verification token
            AuthMailer.with(user: @user).email_verification.deliver_later

          render json: {
            message: "First user registered successfully. Please check your email for verification.",
            user: UserSerializer.new(@user)
          }, status: :created
        else
          render json: {
            error: "Registration failed",
            details: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(
          :email,
          :password,
          :password_confirmation,
          :first_name,
          :last_name
        )
      end

      def first_user_registration?
        User.count.zero?
      end

      def render_first_user_exists
        render json: {
          error: "First user already registered",
          message: "System already has an administrator"
        }, status: :forbidden
      end
    end
  end
end
