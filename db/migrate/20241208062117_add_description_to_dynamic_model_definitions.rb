class AddDescriptionToDynamicModelDefinitions < ActiveRecord::Migration[8.0]
  def change
    add_column :dynamic_model_definitions, :description, :text
  end
end
