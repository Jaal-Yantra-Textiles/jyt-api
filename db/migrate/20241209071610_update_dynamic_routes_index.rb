class UpdateDynamicRoutesIndex < ActiveRecord::Migration[8.0]
  def change
      # Remove the old index
      remove_index :dynamic_routes, :path

      # Add the new compound index
      add_index :dynamic_routes, [ :path, :organization_id, :method ], unique: true
  end
end
