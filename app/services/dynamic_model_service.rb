class DynamicModelService < DynamicModel::Base
  include DynamicModel::Validations
  include DynamicModel::TableOperations
  include DynamicModel::RouteManagement
  include DynamicModel::ModelManagement

  def cleanup
    Rails.logger.info "Starting cleanup for #{model_definition.name}..."

    ActiveRecord::Base.transaction do
      remove_table_with_dependencies
      unload_model_class
      delete_routes_from_db
      reload_routes
    end
  rescue StandardError => e
    Rails.logger.error "Error during cleanup: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  def update(new_attributes)
    Rails.logger.info "Updating model #{model_definition.name}..."

    if new_attributes[:name] && new_attributes[:name] != model_definition.name
      raise DynamicModel::ValidationError, "Changing model name is not supported after creation"
    end

    ActiveRecord::Base.transaction do
      model_definition.assign_attributes(new_attributes)

      if requires_structural_change?
        perform_structural_update
      else
        model_definition.save!
      end
    end
  rescue StandardError => e
    Rails.logger.error "Update failed for #{model_definition.name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

  def requires_structural_change?
    model_definition.field_definitions.any?(&:changed?) ||
      model_definition.relationship_definitions.any?(&:changed?)
  end

  def perform_structural_update
    update_table_structure
    model_definition.save!
    load_model_class
  end

  def base_path
    "/api/v1/org_#{org_id}_#{model_definition.name.underscore.pluralize}"
  end
end
