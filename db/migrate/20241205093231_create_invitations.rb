class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.string :status, null: false, default: 'pending'
      t.references :organization, foreign_key: true, null: false

      t.timestamps
    end
  end
end
