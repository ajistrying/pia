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

ActiveRecord::Schema[7.1].define(version: 2025_05_27_042219) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "company_workspaces", force: :cascade do |t|
    t.string "company_symbol"
    t.string "company_name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "earnings_calls", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "index_earnings_calls_on_company_workspace_id"
  end

  create_table "key_ratios", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "index_key_ratios_on_company_workspace_id"
  end

  create_table "news_pieces", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "index_news_pieces_on_company_workspace_id"
  end

  create_table "sec_filings", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "index_sec_filings_on_company_workspace_id"
  end

  add_foreign_key "earnings_calls", "company_workspaces"
  add_foreign_key "key_ratios", "company_workspaces"
  add_foreign_key "news_pieces", "company_workspaces"
  add_foreign_key "sec_filings", "company_workspaces"
end
