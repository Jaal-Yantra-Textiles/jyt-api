module Api
  module V1
    class OrganizationsController < ApplicationController
      before_action :authenticate_request
      before_action :set_organization, only: %i[show update destroy activate invite_user add_user]

      # GET /api/v1/organizations
      def index
        @organizations = current_user.owned_organizations
        render json: @organizations
      end

      # POST /api/v1/organizations
      def create
        @organization = current_user.owned_organizations.build(organization_params)
        if @organization.save
          render json: @organization, status: :created
        else
          render json: @organization.errors, status: :unprocessable_entity
        end
      end

      # GET /api/v1/organizations/:id
      def show
        render json: @organization
      end

      # PUT/PATCH /api/v1/organizations/:id
      def update
        if @organization.super_admin?(current_user) && @organization.update(organization_params)
          render json: @organization
        else
          render json: { error: "Unauthorized or unable to update organization" }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/organizations/:id
      def destroy
        if @organization.super_admin?(current_user)
          @organization.destroy
          head :no_content
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      # POST /api/v1/organizations/:id/activate
      def activate
        if @organization.super_admin?(current_user) && @organization.update(active: true)
          render json: { message: "Organization activated successfully" }, status: :ok
        else
          render json: { error: "Unauthorized or unable to activate organization" }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/organizations/:id/invite_user
      def invite_user
        email = params[:email]
        if @organization.super_admin?(current_user) && @organization.invite_user(email)
          render json: { message: "Invitation sent successfully" }, status: :ok
        else
          render json: { error: "Unable to send invitation" }, status: :unprocessable_entity
        end
      end

      def add_user
        email = params[:email]
        user = User.find_by(email: email)
        if user && @organization.super_admin?(current_user) && @organization.add_user(user)
          render json: { message: "User added successfully" }, status: :ok
        else
          render json: { error: "Unable to add user" }, status: :unprocessable_entity
        end
      end

      private

      def set_organization
        @organization = Organization.find_by(id: params[:id])
        unless @organization && (@organization.owner == current_user || @organization.members.include?(current_user))
          render json: { error: "Organization not found" }, status: :not_found
        end
      end

      def organization_params
        params.require(:organization).permit(:name, :industry)
      end
    end
  end
end
