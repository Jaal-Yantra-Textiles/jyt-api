module Api
  module V1
    class OrganizationsController < ApplicationController
      before_action :authenticate_request
      before_action :set_organization, only: %i[show update destroy]

      # GET /api/v1/organizations
      def index
        @organizations = current_user.organizations
        render json: @organizations
      end

      # POST /api/v1/organizations
      def create
        @organization = current_user.organizations.build(organization_params)

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
        if @organization.update(organization_params)
          render json: @organization
        else
          render json: @organization.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/organizations/:id
      def destroy
        @organization.destroy
        head :no_content
      end

      private

      def set_organization
        @organization = current_user.organizations.find_by(id: params[:id])
        return render json: { error: 'Organization not found' }, status: :not_found unless @organization
      end

      def organization_params
        params.require(:organization).permit(:name, :industry)
      end
    end
  end
end
