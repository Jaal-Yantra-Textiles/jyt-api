module DynamicModel
    module ModelManagement
      private

      def load_model_class
        Rails.logger.info "Loading model class for #{model_definition.name}..."
        DynamicModelLoader.load_model(model_definition)
      rescue StandardError => e
        raise ModelLoadError, "Failed to load model class: #{e.message}"
      end

      def unload_model_class
        Rails.logger.info "Unloading model class for #{model_definition.name}..."
        DynamicModelLoader.unload_model(class_name)
      rescue StandardError => e
        raise ModelLoadError, "Failed to unload model class: #{e.message}"
      end
    end
end
