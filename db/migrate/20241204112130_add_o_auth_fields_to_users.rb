class AddOAuthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :oauth_provider, :string
    add_column :users, :oauth_token, :string
    add_column :users, :oauth_expires_at, :datetime

    add_index :users, :oauth_provider
    add_index :users, [:oauth_provider, :email]
  end
end
