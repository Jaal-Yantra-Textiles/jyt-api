class AddActiveToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :active, :boolean, default: false, null: false
  end
end
