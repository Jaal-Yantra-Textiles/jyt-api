class CreateJoinTableOrganizationsUsers < ActiveRecord::Migration[8.0]
  def change
      create_table :organizations_users, id: false do |t|
        t.belongs_to :organization
        t.belongs_to :user
        t.timestamps
      end

      add_index :organizations_users, [ :organization_id, :user_id ], unique: true
    end
end
