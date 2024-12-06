module Api
  module V1
    class DynamicModelsController < ApplicationController
      before_action :authenticate_request
      before_action :set_current_organization

      def create
        @model_definition = current_organization.dynamic_model_definitions.new(model_params)

        if @model_definition.save
          render json: {
            data: {
                  attributes: {
                    name: @model_definition.name,
                    organization_id: @model_definition.organization_id,
                    fields_attributes: @model_definition.field_definitions,
                    relationship_definitions_attributes: @model_definition.relationship_definitions
                  }
                }
          }, status: :created
        else
          render json: { errors: @model_definition.errors }, status: :unprocessable_entity
        end
      end

      private

      def model_params
        params.require(:dynamic_model_definition).permit(
          :name, :description,
          field_definitions_attributes: [
            :id, :name, :field_type, { options: {} }, :_destroy
          ],
          relationship_definitions_attributes: [
            :id, :name, :relationship_type, :target_model, :_destroy
          ]
        )
      end

      def set_current_organization
        @current_organization = current_user.all_organizations.find_by(id: params[:organization_id]) ||
                                 current_user.owned_organizations.first

        render json: { error: "Organization not found" }, status: :not_found unless @current_organization
      end

      def current_organization
        @current_organization
      end
    end
  end
end
