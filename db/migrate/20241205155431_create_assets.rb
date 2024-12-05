class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.references :organization, null: false, index: true
      t.references :created_by, null: false, index: true
      t.string :name, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.string :storage_key, null: false
      t.string :storage_path, null: false
      t.integer :storage_provider, null: false
      t.jsonb :metadata, default: {}

      t.timestamps

      t.index [ :organization_id, :storage_key ], unique: true
    end

    add_foreign_key :assets, :organizations
    add_foreign_key :assets, :users, column: :created_by_id
  end

  def down
    remove_foreign_key :assets, :organizations
    remove_foreign_key :assets, :users, column: :created_by_id
    drop_table :assets
  end
end
