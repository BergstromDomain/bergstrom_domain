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

ActiveRecord::Schema[8.1].define(version: 2026_04_17_230032) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_permissions", force: :cascade do |t|
    t.string "app_name", null: false
    t.boolean "can_create", default: false, null: false
    t.boolean "can_delete", default: false, null: false
    t.boolean "can_update", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "app_name"], name: "index_app_permissions_on_user_id_and_app_name", unique: true
    t.index ["user_id"], name: "index_app_permissions_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "contact_id"], name: "index_contacts_on_user_id_and_contact_id", unique: true
  end

  create_table "event_people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "person_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "person_id"], name: "index_event_people_on_event_id_and_person_id", unique: true
  end

  create_table "event_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "icon", null: false
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["icon"], name: "index_event_types_on_icon", unique: true
    t.index ["name"], name: "index_event_types_on_name", unique: true
    t.index ["slug"], name: "index_event_types_on_slug", unique: true
  end

  create_table "events", force: :cascade do |t|
    t.string "classification", default: "contacts", null: false
    t.datetime "created_at", null: false
    t.integer "day", null: false
    t.text "description"
    t.integer "event_type_id", null: false
    t.integer "month", null: false
    t.string "slug"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "year"
    t.index ["event_type_id"], name: "index_events_on_event_type_id"
    t.index ["month", "day"], name: "index_events_on_month_day"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["title"], name: "index_events_on_title", unique: true
    t.index ["user_id"], name: "index_events_on_user_id"
    t.index ["year", "month", "day"], name: "index_events_on_year_month_day"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "first_name", null: false
    t.string "last_name"
    t.string "middle_name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["first_name", "middle_name", "last_name"], name: "index_people_on_full_name"
    t.index ["slug"], name: "index_people_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", default: "app_user", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "app_permissions", "users"
  add_foreign_key "contacts", "users"
  add_foreign_key "contacts", "users", column: "contact_id"
  add_foreign_key "event_people", "events"
  add_foreign_key "event_people", "people"
  add_foreign_key "events", "event_types"
  add_foreign_key "events", "users"
  add_foreign_key "sessions", "users"
end
