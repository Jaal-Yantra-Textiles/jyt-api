class CreateDynamicRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :dynamic_routes do |t|
      t.string :path, null: false
      t.string :controller, null: false
      t.string :action, null: false
      t.string :method, null: false, default: "GET"
      t.integer :organization_id, null: false

      t.timestamps
    end
    add_index :dynamic_routes, :path, unique: true
  end
end
