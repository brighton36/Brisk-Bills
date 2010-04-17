# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 28) do

  create_table "activities", :force => true do |t|
    t.integer  "client_id"
    t.integer  "invoice_id"
    t.boolean  "is_published",  :default => false, :null => false
    t.string   "activity_type"
    t.datetime "occurred_on"
    t.integer  "cost_in_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tax_in_cents"
  end

  add_index "activities", ["client_id"], :name => "index_activities_on_client_id"
  add_index "activities", ["invoice_id"], :name => "index_activities_on_invoice_id"

  create_table "activity_adjustments", :force => true do |t|
    t.integer  "activity_id"
    t.string   "label"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activity_labors", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "activity_id"
    t.text     "comments"
    t.integer  "minute_duration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activity_materials", :force => true do |t|
    t.integer  "activity_id"
    t.string   "label"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activity_proposals", :force => true do |t|
    t.integer  "activity_id"
    t.string   "label"
    t.text     "comments"
    t.datetime "proposed_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activity_types", :force => true do |t|
    t.string   "label"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_eventlogs", :force => true do |t|
    t.integer  "client_id"
    t.text     "description"
    t.datetime "created_at"
  end

  create_table "client_finance_transactions", :force => true do |t|
    t.integer  "client_id"
    t.datetime "date"
    t.binary   "description",     :limit => 16777215
    t.integer  "amount_in_cents", :limit => 34,       :precision => 34, :scale => 0
  end

  create_table "client_finance_transactions_union", :force => true do |t|
    t.integer  "client_id"
    t.datetime "date"
    t.binary   "description",     :limit => 16777215
    t.integer  "amount_in_cents", :limit => 34,       :precision => 34, :scale => 0
  end

  create_table "client_representatives", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.string   "cell_phone"
    t.string   "password"
    t.integer  "accepts_tos_version", :default => 0
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "client_representatives_clients", :id => false, :force => true do |t|
    t.integer "client_id"
    t.integer "client_representative_id"
  end

  add_index "client_representatives_clients", ["client_id"], :name => "index_client_representatives_clients_on_client_id"
  add_index "client_representatives_clients", ["client_representative_id"], :name => "index_client_representatives_clients_on_client_representative_id"

  create_table "clients", :force => true do |t|
    t.string   "company_name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.string   "fax_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",    :default => true, :null => false
  end

  create_table "clients_with_balances", :force => true do |t|
    t.string   "company_name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone_number"
    t.string   "fax_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",                                                                           :default => true, :null => false
    t.integer  "uninvoiced_activities_balance_in_cents", :limit => 33, :precision => 33, :scale => 0
    t.integer  "charges_sum_in_cents",                   :limit => 33, :precision => 33, :scale => 0
    t.integer  "payment_sum_in_cents",                   :limit => 32, :precision => 32, :scale => 0
    t.integer  "balance_in_cents",                       :limit => 34, :precision => 34, :scale => 0
  end

  create_table "clients_with_charges_sum", :id => false, :force => true do |t|
    t.integer "client_id"
    t.integer "charges_sum_in_cents", :limit => 33, :precision => 33, :scale => 0
  end

  create_table "clients_with_payment_sum", :id => false, :force => true do |t|
    t.integer "client_id"
    t.integer "payment_sum_in_cents", :limit => 32, :precision => 32, :scale => 0
  end

  create_table "credentials", :force => true do |t|
    t.string   "email_address"
    t.string   "password_hash"
    t.integer  "failed_login_count",   :default => 0,     :null => false
    t.datetime "failed_login_at"
    t.boolean  "login_enabled",        :default => false, :null => false
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "reset_password_token"
  end

  create_table "employee_client_labor_rates", :force => true do |t|
    t.integer  "employee_id"
    t.integer  "client_id"
    t.integer  "hourly_rate_in_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "employee_client_labor_rates", ["client_id"], :name => "index_employee_client_labor_rates_on_client_id"
  add_index "employee_client_labor_rates", ["employee_id"], :name => "index_employee_client_labor_rates_on_employee_id"

  create_table "employee_slimtimers", :force => true do |t|
    t.integer "employee_id", :null => false
    t.string  "api_key"
    t.string  "username"
    t.string  "password"
  end

  create_table "employees", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "password"
    t.integer  "phone_extension"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_active",       :default => true, :null => false
  end

  create_table "invoice_payments", :force => true do |t|
    t.integer "payment_id",      :null => false
    t.integer "invoice_id",      :null => false
    t.integer "amount_in_cents", :null => false
  end

  add_index "invoice_payments", ["payment_id", "invoice_id"], :name => "index_invoice_payments_on_payment_id_and_invoice_id"

  create_table "invoices", :force => true do |t|
    t.integer  "client_id"
    t.text     "comments"
    t.datetime "issued_on"
    t.boolean  "is_published", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["client_id"], :name => "index_invoices_on_client_id"

  create_table "invoices_activity_types", :id => false, :force => true do |t|
    t.integer "invoice_id"
    t.integer "activity_type_id"
  end

  add_index "invoices_activity_types", ["invoice_id", "activity_type_id"], :name => "index_invoices_activity_types_on_invoice_id_and_activity_type_id"

  create_table "invoices_with_payments", :id => false, :force => true do |t|
    t.integer "invoice_id",                                                        :default => 0, :null => false
    t.integer "amount_paid_in_cents", :limit => 32, :precision => 32, :scale => 0
  end

  create_table "invoices_with_totals", :force => true do |t|
    t.integer  "client_id"
    t.text     "comments"
    t.datetime "issued_on"
    t.boolean  "is_published",                                                      :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "amount_in_cents",      :limit => 33, :precision => 33, :scale => 0
    t.integer  "amount_paid_in_cents", :limit => 32, :precision => 32, :scale => 0
    t.integer  "is_paid",                                                           :default => 0,     :null => false
  end

  create_table "payment_methods", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer  "client_id"
    t.integer  "payment_method_id"
    t.text     "payment_method_identifier"
    t.integer  "amount_in_cents"
    t.datetime "paid_on"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payments", ["client_id"], :name => "index_payments_on_client_id"
  add_index "payments", ["payment_method_id"], :name => "index_payments_on_payment_method_id"

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "keyname"
    t.string   "label"
    t.text     "keyval"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "slimtimer_tasks", :force => true do |t|
    t.integer  "owner_employee_slimtimer_id"
    t.string   "name"
    t.integer  "default_client_id"
    t.datetime "st_created_at"
    t.datetime "st_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "slimtimer_time_entries", :force => true do |t|
    t.integer  "employee_slimtimer_id"
    t.integer  "slimtimer_task_id"
    t.integer  "activity_labor_id"
    t.text     "comments"
    t.text     "tags"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "st_updated_at"
    t.datetime "st_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
