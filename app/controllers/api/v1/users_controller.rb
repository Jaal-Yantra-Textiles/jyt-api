module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_request
      before_action :set_user, only: [ :update, :destroy ]
      before_action :authorize_user, only: [ :update, :destroy ]
      before_action :authorize_admin, only: [ :create ]

      # GET /api/v1/users/current
      def profile
        render json: {
          user: UserSerializer.new(@current_user),
          organizations: {
            owned: @current_user.owned_organizations,
            member: @current_user.member_organizations
          }
        }
      end

      # GET /api/v1/users
      def index
        @users = User.all
        render json: {
          users: ActiveModel::Serializer::CollectionSerializer.new(
            @users,
            serializer: UserSerializer
          )
        }
      end

      # GET /api/v1/users/:id
      def show
        @user = User.find(params[:id])
        render json: {
          user: UserSerializer.new(@user),
          organizations: {
            owned: @user.owned_organizations,
            member: @user.member_organizations
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      # POST /api/v1/users
      def create
        user = User.new(user_params)
        if user.save
          render json: {
            user: UserSerializer.new(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/users/:id
      def update
        if @user.update(update_user_params)
          render json: {
            user: UserSerializer.new(@user)
          }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        if @user.destroy
          render json: { message: "User successfully deleted" }
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/social_connections
      def social_connections
        connections = @current_user.social_accounts.includes(:provider)
        render json: {
          connections: connections.map do |connection|
            {
              provider: connection.provider,
              connected_at: connection.created_at,
              expires_at: connection.oauth_expires_at
            }
          end
        }
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
      end

      def authorize_user
        unless @user == @current_user || @current_user.admin?
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def authorize_admin
        unless @current_user.admin?
          render json: { error: "Only administrators can create new users" },
                 status: :unauthorized
        end
      end

      def user_params
        allowed_params = [ :email, :password, :password_confirmation, :first_name, :last_name ]
        allowed_params << :role if current_user&.admin?
        params.require(:user).permit(*allowed_params)
      end

      def update_user_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :email,
          :password,
          :password_confirmation
        )
      end
    end
  end
end
