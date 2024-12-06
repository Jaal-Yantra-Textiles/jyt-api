class AddNewColumsToDynamicModels < ActiveRecord::Migration[8.0]
  def change
      add_reference :dynamic_model_definitions, :organization, null: false, foreign_key: true
      add_column :dynamic_model_definitions, :metadata, :jsonb, default: {}
      add_index :dynamic_model_definitions, [ :organization_id, :name ], unique: true
    end
end
