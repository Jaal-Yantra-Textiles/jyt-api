module DynamicModel
    class Error < StandardError; end
    class ValidationError < Error; end
    class TableOperationError < Error; end
    class ModelLoadError < Error; end
    class RouteError < Error; end

    class Base
      include Constants
      include Validations

      attr_reader :model_definition, :org_id

      def initialize(model_definition)
        @model_definition = model_definition
        @org_id = model_definition.organization_id
        validate_model_definition!
      end

      def generate
        Rails.logger.info "Generating dynamic model for #{model_definition.name}..."

        ActiveRecord::Base.transaction do
          ensure_table_exists
          @model_class = DynamicModelLoader.load_model(
            model_definition
          )
          setup_field_validations(@model_class)
          Rails.logger.info "Model class loaded: #{@model_class.inspect}"
          Rails.logger.info "Model relationships: #{@model_class.reflect_on_all_associations.map(&:name)}"

          store_routes_in_db
          reload_routes
        end

        true
      rescue StandardError => e
        Rails.logger.error "Failed to generate dynamic model: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise
      end

      private

      def table_name
        "org_#{org_id}_#{model_definition.name.underscore.pluralize}"
      end

      def class_name
        "Org#{org_id}#{model_definition.name.camelize}"
      end
    end
end
