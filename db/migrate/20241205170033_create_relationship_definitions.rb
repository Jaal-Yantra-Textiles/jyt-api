class CreateRelationshipDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :relationship_definitions do |t|
      t.references :dynamic_model_definition, null: false, foreign_key: true
      t.string :name, null: false
      t.string :relationship_type, null: false
      t.string :target_model, null: false
      t.json :options

      t.timestamps
    end
  end
end
