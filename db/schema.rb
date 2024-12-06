# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_12_06_164636) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "created_by_id", null: false
    t.string "name", null: false
    t.string "content_type", null: false
    t.bigint "byte_size", null: false
    t.string "storage_key", null: false
    t.string "storage_path", null: false
    t.integer "storage_provider", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_assets_on_created_by_id"
    t.index ["organization_id", "storage_key"], name: "index_assets_on_organization_id_and_storage_key", unique: true
    t.index ["organization_id"], name: "index_assets_on_organization_id"
  end

  create_table "dynamic_model_definitions", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.jsonb "metadata", default: {}
    t.index ["organization_id", "name"], name: "index_dynamic_model_definitions_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_dynamic_model_definitions_on_organization_id"
  end

  create_table "field_definitions", force: :cascade do |t|
    t.bigint "dynamic_model_definition_id", null: false
    t.string "name", null: false
    t.string "field_type", null: false
    t.json "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dynamic_model_definition_id"], name: "index_field_definitions_on_dynamic_model_definition_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "email", null: false
    t.string "status", default: "pending", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "industry"
    t.integer "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false, null: false
  end

  create_table "organizations_users", id: false, force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "user_id"], name: "index_organizations_users_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id"
    t.index ["user_id"], name: "index_organizations_users_on_user_id"
  end

  create_table "relationship_definitions", force: :cascade do |t|
    t.bigint "dynamic_model_definition_id", null: false
    t.string "name", null: false
    t.string "relationship_type", null: false
    t.string "target_model", null: false
    t.json "options", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dynamic_model_definition_id"], name: "index_relationship_definitions_on_dynamic_model_definition_id"
  end

  create_table "social_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_social_accounts_on_uid"
    t.index ["user_id"], name: "index_social_accounts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "first_name"
    t.string "last_name"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "email_verification_token"
    t.datetime "email_verified_at"
    t.string "oauth_provider"
    t.string "oauth_token"
    t.datetime "oauth_expires_at"
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token"
    t.index ["oauth_provider", "email"], name: "index_users_on_oauth_provider_and_email"
    t.index ["oauth_provider"], name: "index_users_on_oauth_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  add_foreign_key "assets", "organizations"
  add_foreign_key "assets", "users", column: "created_by_id"
  add_foreign_key "dynamic_model_definitions", "organizations"
  add_foreign_key "field_definitions", "dynamic_model_definitions"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "organizations_users", "organizations"
  add_foreign_key "organizations_users", "users"
  add_foreign_key "relationship_definitions", "dynamic_model_definitions"
  add_foreign_key "social_accounts", "users"
end
