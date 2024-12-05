class CreateSocialAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :uid

      t.timestamps
    end
    add_index :social_accounts, :uid
  end
end
