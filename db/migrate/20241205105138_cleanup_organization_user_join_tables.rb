class CleanupOrganizationUserJoinTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :users_organizations if table_exists?(:users_organizations)

    # Ensure organizations_users has the correct structure
    change_column_null :organizations_users, :organization_id, false
    change_column_null :organizations_users, :user_id, false

    # Add foreign keys if they don't exist
    unless foreign_key_exists?(:organizations_users, :organizations)
      add_foreign_key :organizations_users, :organizations
    end

    unless foreign_key_exists?(:organizations_users, :users)
      add_foreign_key :organizations_users, :users
    end
  end

  def down
    # Recreate the users_organizations table
    create_table :users_organizations do |t|
      t.references :user, null: false
      t.references :organization, null: false
      t.timestamps
    end

    # Make the columns nullable again
    change_column_null :organizations_users, :organization_id, true
    change_column_null :organizations_users, :user_id, true

    # Remove the foreign keys
    remove_foreign_key :organizations_users, :organizations if foreign_key_exists?(:organizations_users, :organizations)
    remove_foreign_key :organizations_users, :users if foreign_key_exists?(:organizations_users, :users)
  end
end
