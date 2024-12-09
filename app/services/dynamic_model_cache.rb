class DynamicModelCache
    class << self
      def store_model(model_definition)
        Rails.cache.write(
          cache_key(model_definition),
          {
            class_definition: serialize_model(model_definition),
            timestamp: Time.current
          },
          expires_in: 24.hours
        )
      end

      def fetch_model(model_definition)
        Rails.cache.fetch(cache_key(model_definition))
      end

      private

      def cache_key(model_definition)
        "dynamic_model:#{model_definition.organization_id}:#{model_definition.name}"
      end

      def serialize_model(model_definition)
        {
          table_name: "org_#{model_definition.organization_id}_#{model_definition.name.underscore.pluralize}",
          fields: model_definition.field_definitions.map(&:attributes),
          relationships: model_definition.relationship_definitions.map(&:attributes),
          validations: extract_validations(model_definition)
        }
      end

      def extract_validations(model_definition)
        model_definition.field_definitions.each_with_object({}) do |field, validations|
          next unless field.options&.dig("validations") || field.options&.dig(:validations)
          validations[field.name] = field.options["validations"] || field.options[:validations]
        end
      end
    end
end
