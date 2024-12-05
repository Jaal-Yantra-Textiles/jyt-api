class CreateFieldDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :field_definitions do |t|
      t.references :dynamic_model_definition, null: false, foreign_key: true
      t.string :name, null: false
      t.string :field_type, null: false
      t.json :options

      t.timestamps
    end
  end
end
