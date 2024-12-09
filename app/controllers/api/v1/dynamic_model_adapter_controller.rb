module Api
    module V1
      class DynamicModelAdapterController < ApplicationController
        before_action :authenticate_request
        before_action :set_model_class

        def index
          if set_model_class
            records = @model_class.all
            render json: { data: records }, status: :ok
          else
            render json: { error: @model_load_error }, status: :not_found
          end
        end

        def show
          if set_model_class
            record = @model_class.find(params[:id])
            render json: { data: record }, status: :ok
          else
            render json: { error: @model_load_error }, status: :not_found
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Record not found" }, status: :not_found
        end

        def create
          if set_model_class
            record = @model_class.new(record_params)
            if record.save
              render json: { data: record }, status: :created
            else
              render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
            end
          else
            render json: { error: @model_load_error }, status: :not_found
          end
        end

        def update
          if set_model_class
            record = @model_class.find(params[:id])
            if record.update(record_params)
              render json: { data: record }, status: :ok
            else
              render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
            end
          else
            render json: { error: @model_load_error }, status: :not_found
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Record not found" }, status: :not_found
        end

        def destroy
          if set_model_class
            record = @model_class.find(params[:id])
            record.destroy
            head :no_content
          else
            render json: { error: @model_load_error }, status: :not_found
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Record not found" }, status: :not_found
        end

        private

        # Dynamically determine the model class from the model_name
        def set_model_class
          begin
            model_name = params[:model_name].classify
            dynamic_model_definition = DynamicModelDefinition.find_by(name: model_name, organization_id: current_organization.id)

            if dynamic_model_definition.nil?
              @model_load_error = "Dynamic model not found"
              return false
            end

            @model_class = DynamicModelLoader.load_model(dynamic_model_definition)
            true
          rescue NameError, StandardError => e
            @model_load_error = "Dynamic model not found"
            false
          end
        end


        # Permit dynamic fields and relationships
        def record_params
          dynamic_model_definition = DynamicModelDefinition.find_by(name: params[:model_name].camelize, organization_id: current_organization.id)
          fields = dynamic_model_definition.field_definitions.map(&:name)
          relationships = dynamic_model_definition.relationship_definitions.select { |rel| rel.relationship_type == "belongs_to" }.map { |rel| "#{rel.name}_id" }

          params.require(params[:model_name].singularize).permit(*(fields + relationships))
        end

        # Get the current organization
        def current_organization
          @current_organization ||= begin
            org = current_user.all_organizations.find_by(id: params[:organization_id]) ||
                  current_user.owned_organizations.first
            unless org
              render json: { error: "Organization not found" }, status: :not_found
              return nil
            end
            org
          end
        end
      end
    end
end
