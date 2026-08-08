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

ActiveRecord::Schema[8.1].define(version: 2026_08_08_005059) do
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

  create_table "forecast_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "gmv_real", default: "0.0", null: false
    t.integer "month", null: false
    t.text "notas"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "year", null: false
    t.index ["user_id", "year", "month"], name: "index_forecast_entries_on_user_id_and_year_and_month", unique: true
    t.index ["user_id"], name: "index_forecast_entries_on_user_id"
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "assigned_by_id", null: false
    t.text "comentarios"
    t.datetime "created_at", null: false
    t.decimal "gmv_meta", default: "0.0", null: false
    t.decimal "income_pct", default: "0.15", null: false
    t.integer "month", null: false
    t.jsonb "okr_asistencia", default: [], null: false
    t.jsonb "okr_gestion", default: [], null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "year", null: false
    t.index ["assigned_by_id"], name: "index_goals_on_assigned_by_id"
    t.index ["user_id", "year", "month"], name: "index_goals_on_user_id_and_year_and_month", unique: true
    t.index ["user_id"], name: "index_goals_on_user_id"
  end

  create_table "one_on_one_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "month", null: false
    t.jsonb "okr_asistencia_real", default: [], null: false
    t.jsonb "okr_gestion_real", default: [], null: false
    t.text "puntos_fuertes"
    t.text "puntos_mejora"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "year", null: false
    t.index ["user_id", "year", "month"], name: "index_one_on_one_entries_on_user_id_and_year_and_month", unique: true
    t.index ["user_id"], name: "index_one_on_one_entries_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.string "cargo"
    t.string "celular"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "nombre", null: false
    t.string "password_digest", null: false
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.jsonb "permisos_custom", default: {}, null: false
    t.string "plain_password"
    t.string "rol", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["password_reset_token"], name: "index_users_on_password_reset_token", unique: true, where: "(password_reset_token IS NOT NULL)"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "forecast_entries", "users"
  add_foreign_key "goals", "users"
  add_foreign_key "goals", "users", column: "assigned_by_id"
  add_foreign_key "one_on_one_entries", "users"
end
