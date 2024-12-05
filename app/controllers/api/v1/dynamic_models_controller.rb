module Api
  module V1
    class DynamicModelsController < ApplicationController
      def create
        @model_definition = DynamicModelDefinition.new(model_params)

        if @model_definition.save
          render json: ModelDefinitionSerializer.new(@model_definition).serializable_hash,
                 status: :created
        else
          render json: @model_definition.errors, status: :unprocessable_entity
        end
      end

      private

      def model_params
              params.require(:model).permit(
                :name,
                field_definitions_attributes: [ # Changed from fields_attributes
                  :name,
                  :field_type,
                  options: {}
                ],
                relationship_definitions_attributes: [ # Changed from relationships_attributes
                  :name,
                  :relationship_type,
                  :target_model,
                  options: {}
                ]
              )
      end
    end
  end
end
