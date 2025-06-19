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

ActiveRecord::Schema[7.1].define(version: 2025_06_18_230923) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "analyst_ratings", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.string "rating_agency"
    t.string "rating"
    t.decimal "price_target"
    t.date "target_date"
    t.string "analyst_name"
    t.text "notes"
    t.date "created_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "index_analyst_ratings_on_company_workspace_id"
  end

  create_table "company_workspace_processing_tasks", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.string "task_type"
    t.datetime "started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "idx_on_company_workspace_id_e31b0c615a"
  end

  create_table "company_workspaces", force: :cascade do |t|
    t.string "company_symbol"
    t.string "company_name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_successful_update"
    t.datetime "initialized_at"
    t.datetime "last_update_started_at"
    t.string "processing_status"
    t.integer "progress_percentage"
    t.index ["company_symbol", "company_name"], name: "index_company_workspaces_on_company_symbol_and_company_name", unique: true
  end

  create_table "earnings_calls", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.string "quarter"
    t.text "transcript"
    t.text "summary"
    t.index ["company_workspace_id"], name: "index_earnings_calls_on_company_workspace_id"
  end

  create_table "financial_statements", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.string "statement_type"
    t.string "period"
    t.integer "year"
    t.integer "quarter"
    t.decimal "revenue"
    t.decimal "gross_profit"
    t.decimal "operating_income"
    t.decimal "net_income"
    t.decimal "total_assets"
    t.decimal "total_debt"
    t.decimal "shareholders_equity"
    t.decimal "operating_cash_flow"
    t.decimal "free_cash_flow"
    t.decimal "eps"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id"], name: "index_financial_statements_on_company_workspace_id"
  end

  create_table "key_ratios", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ratio_name"
    t.decimal "ratio_value"
    t.string "period"
    t.integer "year"
    t.integer "quarter"
    t.boolean "ttm"
    t.index ["company_workspace_id"], name: "index_key_ratios_on_company_workspace_id"
  end

  create_table "news_pieces", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.string "url"
    t.datetime "published_date"
    t.string "author"
    t.text "content"
    t.text "summary"
    t.index ["company_workspace_id"], name: "index_news_pieces_on_company_workspace_id"
  end

  create_table "sec_filings", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cik"
    t.date "filing_date"
    t.string "form_type"
    t.string "sec_link"
    t.string "final_link"
    t.text "summary"
    t.datetime "processed_at"
    t.index ["company_workspace_id"], name: "index_sec_filings_on_company_workspace_id"
  end

  create_table "workspace_task_completions", force: :cascade do |t|
    t.bigint "company_workspace_id", null: false
    t.string "task_type", null: false
    t.datetime "completed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_workspace_id", "task_type"], name: "unique_workspace_task_completion", unique: true
    t.index ["company_workspace_id"], name: "index_workspace_task_completions_on_company_workspace_id"
  end

  add_foreign_key "analyst_ratings", "company_workspaces"
  add_foreign_key "company_workspace_processing_tasks", "company_workspaces"
  add_foreign_key "earnings_calls", "company_workspaces"
  add_foreign_key "financial_statements", "company_workspaces"
  add_foreign_key "key_ratios", "company_workspaces"
  add_foreign_key "news_pieces", "company_workspaces"
  add_foreign_key "sec_filings", "company_workspaces"
  add_foreign_key "workspace_task_completions", "company_workspaces"
end
