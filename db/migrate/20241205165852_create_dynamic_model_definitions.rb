class CreateDynamicModelDefinitions < ActiveRecord::Migration[8.0]
  def change
    create_table :dynamic_model_definitions do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
