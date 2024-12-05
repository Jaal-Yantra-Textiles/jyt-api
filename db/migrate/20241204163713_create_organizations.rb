class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :industry
      t.integer :owner_id

      t.timestamps
    end
  end
end
