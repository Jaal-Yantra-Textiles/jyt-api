class CreateUsersOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :users_organizations do |t|
      t.references :organization, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
