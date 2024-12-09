module Api
  module V1
    class DynamicModelsController < ApplicationController
      before_action :authenticate_request
      before_action :set_current_organization
      before_action :set_model_definition, only: [ :show, :update, :destroy ]
      rescue_from DynamicModel::ValidationError, with: :render_validation_error

      # GET /api/v1/dynamic_models/:id
      def show
        render json: {
          data: {
            id: @model_definition.id,
            type: "dynamic_model_definition",
            attributes: model_definition_attributes(@model_definition).merge(
              organization_id: @model_definition.organization_id
            )
          }
        }
      end

      # POST /api/v1/dynamic_models
      def create
        @model_definition = current_organization.dynamic_model_definitions.new(model_params)

        if @model_definition.save
          # Initialize and generate dynamic model components
          service = DynamicModelService.new(@model_definition)
          service.generate

          render json: {
            data: {
              id: @model_definition.id,
              type: "dynamic_model_definition",
              attributes: model_definition_attributes(@model_definition).merge(
                organization_id: @model_definition.organization_id
              )
            }
          }, status: :created
        else
          render json: { errors: @model_definition.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/dynamic_models/:id
      def destroy
        # Clean up dynamic model components before destroying the definition
        service = DynamicModelService.new(@model_definition)
        service.cleanup

        @model_definition.destroy
        head :no_content
      end

      # PATCH/PUT /api/v1/dynamic_models/:id
      def update
        service = DynamicModelService.new(@model_definition)

        if service.update(model_params)
          render json: {
            data: {
              id: @model_definition.id,
              type: "dynamic_model_definition",
              attributes: model_definition_attributes(@model_definition).merge(
                organization_id: @model_definition.organization_id
              )
            }
          }
        else
          render json: DynamicModelDefinitionSerializer.new(@dynamic_model).serializable_hash
        end
      end

      private

      # Helper method to format model definition attributes
      def model_definition_attributes(model)
        ModelDefinitionSerializer.new(model).serializable_hash[:data][:attributes]
      end

      # Strong parameters for dynamic model definitions
      def model_params
        params.require(:dynamic_model_definition).permit(
          :name, :description, :organization_id,
          field_definitions_attributes: [
            :id, :name, :field_type, { options: {} }, :_destroy
          ],
          relationship_definitions_attributes: [
            :id, :name, :relationship_type, :target_model, :_destroy
          ]
        )
      end

      # Set the current organization based on the request
      def set_current_organization
        @current_organization = current_user.all_organizations.find_by(id: params[:organization_id]) ||
          current_user.owned_organizations.first
        render json: { error: "Organization not found" }, status: :not_found unless @current_organization
      end

      # Find the model definition by ID
      def set_model_definition
        @model_definition = current_organization.dynamic_model_definitions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Dynamic model definition not found" }, status: :not_found
      end

      # Alias for the current organization
      def current_organization
        @current_organization
      end

      def render_validation_error(exception)
        render json: { errors: [ exception.message ] }, status: :unprocessable_entity
      end
    end
  end
end
