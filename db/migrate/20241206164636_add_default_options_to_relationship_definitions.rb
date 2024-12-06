class AddDefaultOptionsToRelationshipDefinitions < ActiveRecord::Migration[8.0]
  def change
    change_column_default :relationship_definitions, :options, {}
  end
end
