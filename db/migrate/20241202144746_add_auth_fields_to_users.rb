class AddAuthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :reset_password_token, :string
    add_index :users, :reset_password_token
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :email_verification_token, :string
    add_index :users, :email_verification_token
    add_column :users, :email_verified_at, :datetime
  end
end
