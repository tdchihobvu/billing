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

ActiveRecord::Schema[7.1].define(version: 2026_11_09_022348) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "banks", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "bank_name", null: false
    t.string "account_name", null: false
    t.string "account_number", null: false
    t.string "branch", null: false
    t.string "swift_code"
    t.bigint "currency_id", null: false
    t.boolean "active", default: true
    t.string "description", null: false
    t.index ["currency_id"], name: "index_banks_on_currency_id"
    t.index ["tenant_id"], name: "index_banks_on_tenant_id"
  end

  create_table "banks_invoices", id: false, force: :cascade do |t|
    t.bigint "bank_id", null: false
    t.bigint "invoice_id", null: false
  end

  create_table "branches", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.integer "tenant_id", null: false
    t.string "name", null: false
    t.string "address_1", null: false
    t.string "address_2"
    t.string "location", null: false
    t.string "city"
    t.string "country"
    t.bigint "license_category_id", null: false
    t.bigint "license_option_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_branches_on_client_id"
    t.index ["license_category_id"], name: "index_branches_on_license_category_id"
    t.index ["license_option_id"], name: "index_branches_on_license_option_id"
    t.index ["name", "client_id", "tenant_id"], name: "unique_client_branches", unique: true
  end

  create_table "branches_invoices", id: false, force: :cascade do |t|
    t.bigint "branch_id", null: false
    t.bigint "invoice_id", null: false
  end

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "client_types", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "client_type_id", null: false
    t.bigint "industry_id", null: false
    t.string "name", null: false
    t.string "trading_name"
    t.string "bp_number"
    t.string "vat_number"
    t.string "address_1", null: false
    t.string "address_2"
    t.string "location"
    t.string "city", null: false
    t.string "country", null: false
    t.string "website"
    t.string "mobile"
    t.string "phone", null: false
    t.string "email", null: false
    t.string "cp_name", null: false
    t.string "cp_mobile"
    t.string "cp_email"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_account_number", null: false
    t.string "gps_latitude"
    t.string "gps_longitude"
    t.string "source_reference"
    t.string "terminal_id"
    t.decimal "total_invoices", precision: 18, scale: 2, default: "0.0"
    t.decimal "total_receipts", precision: 18, scale: 2, default: "0.0"
    t.decimal "balance", precision: 18, scale: 2, default: "0.0"
    t.datetime "last_statement_update"
    t.integer "currency_id", default: 1
    t.string "prefix"
    t.decimal "balance_bf", precision: 18, scale: 2, default: "0.0"
    t.integer "bf_currency_id"
    t.index ["client_type_id"], name: "index_clients_on_client_type_id"
    t.index ["industry_id"], name: "index_clients_on_industry_id"
    t.index ["tenant_id", "client_account_number"], name: "account_numbers_unique", unique: true
    t.index ["tenant_id", "name"], name: "index_clients_on_tenant_id_and_name", unique: true
    t.index ["tenant_id"], name: "index_clients_on_tenant_id"
  end

  create_table "config_keys", force: :cascade do |t|
    t.string "name"
    t.bigint "setting_category_id", null: false
    t.index ["setting_category_id"], name: "index_config_keys_on_setting_category_id"
  end

  create_table "contact_people", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "firstname"
    t.string "lastname"
    t.string "designation"
    t.string "email"
    t.string "mobile_1"
    t.string "mobile_2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_contact_people_on_tenant_id"
  end

  create_table "credit_notes", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.datetime "transaction_date", null: false
    t.string "document_number", null: false
    t.string "reference_number", null: false
    t.text "reason", null: false
    t.decimal "invoice_amount", precision: 18, scale: 4, default: "0.0"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["document_number", "reference_number"], name: "unique_invoice_reference", unique: true
    t.index ["invoice_id"], name: "index_credit_notes_on_invoice_id"
    t.index ["user_id"], name: "index_credit_notes_on_user_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "name", null: false
    t.string "symbol", null: false
    t.string "origin"
    t.decimal "rate", precision: 12, scale: 5, default: "0.0"
    t.boolean "active", default: true
    t.string "trcode"
    t.string "account_reference"
    t.index ["name"], name: "index_currencies_on_name", unique: true
  end

  create_table "currencies_payment_forms", id: false, force: :cascade do |t|
    t.bigint "currency_id", null: false
    t.bigint "payment_form_id", null: false
  end

  create_table "device_settings", force: :cascade do |t|
    t.string "device_id", null: false
    t.string "device_token", null: false
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "regional_office_id", null: false
    t.string "name", null: false
    t.string "terminal_id", null: false
    t.string "serial_number", null: false
    t.string "model"
    t.boolean "active", default: false
    t.bigint "user_id", null: false
    t.text "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "available", default: true
    t.index ["regional_office_id"], name: "index_devices_on_regional_office_id"
    t.index ["serial_number"], name: "unique_serial_number", unique: true
    t.index ["tenant_id"], name: "index_devices_on_tenant_id"
    t.index ["terminal_id"], name: "unique_terminal_id", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "districts", force: :cascade do |t|
    t.integer "region_id", null: false
    t.string "name", null: false
  end

  create_table "dump_invoices", force: :cascade do |t|
    t.string "username"
    t.string "shiftid"
    t.string "district"
    t.string "clientname"
    t.string "invoicedate"
    t.string "invoiceref"
    t.string "itemdescription"
    t.string "gpslatitude"
    t.string "gpslongitude"
    t.string "amountdue"
    t.string "renwalmonth"
    t.string "licenseoption"
    t.string "licensecategory"
    t.string "licensedays"
    t.string "invoicecurrency"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_dump_invoices_on_user_id"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.integer "currency_id", null: false
    t.date "transaction_date", null: false
    t.decimal "buying_rate", precision: 12, scale: 5, null: false
    t.decimal "midrate", precision: 12, scale: 5, null: false
    t.decimal "selling_rate", precision: 12, scale: 5, null: false
    t.decimal "alternative_rate", precision: 12, scale: 5, null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tenant_id"
    t.index ["currency_id", "transaction_date"], name: "unique_currency_rates", unique: true
  end

  create_table "goods_received_items", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "goods_received_id", null: false
    t.string "description", null: false
    t.decimal "net_cost", precision: 18, scale: 4, default: "0.0"
    t.decimal "cost_vat", precision: 18, scale: 4, default: "0.0"
    t.decimal "cost", precision: 18, scale: 4, default: "0.0"
    t.decimal "quantity", precision: 8, scale: 3, default: "0.0"
    t.decimal "net_total_cost", precision: 18, scale: 4, default: "0.0"
    t.decimal "total_vat", precision: 18, scale: 4, default: "0.0"
    t.decimal "total_cost", precision: 18, scale: 4, default: "0.0"
    t.decimal "net_selling_price", precision: 18, scale: 4, default: "0.0"
    t.decimal "selling_price", precision: 18, scale: 4, default: "0.0"
    t.bigint "vat_type_id", null: false
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["goods_received_id"], name: "index_goods_received_items_on_goods_received_id"
    t.index ["product_id"], name: "index_goods_received_items_on_product_id"
    t.index ["vat_type_id"], name: "index_goods_received_items_on_vat_type_id"
  end

  create_table "goods_receiveds", force: :cascade do |t|
    t.string "grv_number", null: false
    t.string "ext_number"
    t.bigint "supplier_id", null: false
    t.bigint "tenant_id", null: false
    t.date "date_received", null: false
    t.bigint "user_id", null: false
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_goods_receiveds_on_supplier_id"
    t.index ["tenant_id"], name: "index_goods_receiveds_on_tenant_id"
    t.index ["user_id"], name: "index_goods_receiveds_on_user_id"
  end

  create_table "industries", force: :cascade do |t|
    t.string "name", null: false
    t.integer "tenant_id"
    t.decimal "amount", precision: 18, scale: 2, default: "0.0"
  end

  create_table "invoice_categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description", null: false
    t.integer "quantity", default: 1
    t.decimal "unit_price", precision: 18, scale: 4, default: "0.0"
    t.decimal "vat", precision: 18, scale: 4, default: "0.0"
    t.decimal "line_total", precision: 18, scale: 4, default: "0.0"
    t.decimal "line_vat", precision: 18, scale: 4, default: "0.0"
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vat_type_id", null: false
    t.decimal "net_price", precision: 24, scale: 6, default: "0.0"
    t.string "item_code"
    t.decimal "discount", precision: 15, scale: 2, default: "0.0"
    t.index ["description", "invoice_id"], name: "invoice_item_unique", unique: true
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.date "invoice_date"
    t.string "invoice_number"
    t.integer "device_id"
    t.bigint "currency_id", null: false
    t.bigint "bank_id"
    t.boolean "deleted", default: false
    t.boolean "is_proforma", default: false
    t.boolean "sent", default: false
    t.boolean "paid", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "invoice_category_id"
    t.boolean "license", default: false
    t.string "order_number"
    t.string "product_pricing", null: false
    t.string "shift_id"
    t.string "gps_longitude"
    t.string "gps_latitude"
    t.string "source_reference"
    t.boolean "is_synced", default: true
    t.integer "tenant_id", null: false
    t.string "description"
    t.decimal "amount_paid", precision: 18, scale: 2, default: "0.0"
    t.date "due_date"
    t.datetime "last_debtors_update"
    t.datetime "last_payment_update"
    t.integer "debtors_age"
    t.decimal "invoice_total", precision: 18, scale: 2, default: "0.0"
    t.string "user_fullname"
    t.string "status", default: "Not Paid", null: false
    t.datetime "last_status_update"
    t.date "void_date"
    t.string "void_reason"
    t.decimal "rate", precision: 12, scale: 5, default: "0.0"
    t.decimal "converted_rate", precision: 12, scale: 5, default: "0.0"
    t.decimal "discount", precision: 15, scale: 2, default: "0.0"
    t.decimal "subtotal", precision: 15, scale: 2, default: "0.0"
    t.decimal "vat_amount", precision: 15, scale: 2, default: "0.0"
    t.index ["bank_id"], name: "index_invoices_on_bank_id"
    t.index ["client_id"], name: "index_invoices_on_client_id"
    t.index ["currency_id"], name: "index_invoices_on_currency_id"
    t.index ["invoice_date", "client_id", "invoice_total", "deleted"], name: "unique_invoice_per_client", unique: true
    t.index ["invoice_date"], name: "index_invoices_on_invoice_date"
    t.index ["invoice_number", "is_proforma", "device_id", "deleted"], name: "invoice_number_unique", unique: true
    t.index ["last_debtors_update"], name: "index_invoices_on_last_debtors_update"
    t.index ["user_id"], name: "index_invoices_on_user_id"
  end

  create_table "license_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "license_options", force: :cascade do |t|
    t.string "name", null: false
    t.integer "months", default: 1
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "count_by", default: "months"
  end

  create_table "licenses", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "license_key"
    t.bigint "license_category_id", null: false
    t.date "renewal_date", null: false
    t.date "expiry_date", null: false
    t.boolean "auto_renewal", default: true
    t.bigint "license_option_id", null: false
    t.integer "printed", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "invoice_id", null: false
    t.integer "branch_id"
    t.boolean "is_parent", default: true
    t.integer "quantity", default: 1
    t.decimal "amount", precision: 18, scale: 2, default: "0.0"
    t.integer "special_days", default: 1
    t.boolean "is_special", default: false
    t.boolean "paid", default: false
    t.string "status", default: "Not Paid", null: false
    t.index ["client_id"], name: "index_licenses_on_client_id"
    t.index ["invoice_id"], name: "index_licenses_on_invoice_id"
    t.index ["license_category_id"], name: "index_licenses_on_license_category_id"
    t.index ["license_option_id"], name: "index_licenses_on_license_option_id"
  end

  create_table "measuring_units", force: :cascade do |t|
    t.string "name"
    t.string "symbol"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.string "message"
    t.boolean "read", default: false
    t.integer "processed_by"
    t.string "process_url"
    t.boolean "processed", default: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_forms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_setoff", default: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "parent_id"], name: "index_product_categories_on_name_and_parent_id", unique: true
  end

  create_table "product_types", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_product_types_on_name", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "description"
    t.string "barcode"
    t.bigint "product_category_id", null: false
    t.bigint "product_type_id", null: false
    t.bigint "brand_id", null: false
    t.bigint "measuring_unit_id", null: false
    t.bigint "vat_type_id", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode", "name"], name: "index_products_on_barcode_and_name", unique: true
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["measuring_unit_id"], name: "index_products_on_measuring_unit_id"
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["vat_type_id"], name: "index_products_on_vat_type_id"
  end

  create_table "quotation_items", force: :cascade do |t|
    t.bigint "quotation_id", null: false
    t.string "description", null: false
    t.integer "quantity", default: 1
    t.decimal "unit_price", precision: 18, scale: 4, default: "0.0"
    t.decimal "vat", precision: 18, scale: 4, default: "0.0"
    t.decimal "line_total", precision: 18, scale: 4, default: "0.0"
    t.decimal "line_vat", precision: 18, scale: 4, default: "0.0"
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vat_type_id", null: false
    t.decimal "net_price", precision: 24, scale: 6, default: "0.0"
    t.index ["quotation_id"], name: "index_quotation_items_on_quotation_id"
  end

  create_table "quotations", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.date "quotation_date"
    t.string "quotation_number"
    t.text "quotation_terms"
    t.bigint "currency_id", null: false
    t.integer "bank_id"
    t.boolean "deleted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "order_number"
    t.integer "validity", null: false
    t.string "product_pricing", null: false
    t.index ["client_id"], name: "index_quotations_on_client_id"
    t.index ["currency_id"], name: "index_quotations_on_currency_id"
    t.index ["user_id"], name: "index_quotations_on_user_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "currency_id", null: false
    t.bigint "payment_form_id", null: false
    t.bigint "user_id", null: false
    t.datetime "transaction_date", null: false
    t.string "reference_number", null: false
    t.decimal "amount", precision: 18, scale: 2, default: "0.0"
    t.decimal "rate", precision: 18, scale: 4, default: "0.0"
    t.string "description", null: false
    t.boolean "deleted", default: false
    t.integer "invoice_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "transaction_source", null: false
    t.integer "transaction_source_id"
    t.string "business_nature"
    t.integer "shift_id"
    t.integer "device_id"
    t.string "gps_longitude"
    t.string "gps_latitude"
    t.boolean "is_synced", default: false
    t.datetime "expiry_date"
    t.integer "transaction_type_id"
    t.string "source_reference", null: false
    t.integer "tenant_id", null: false
    t.decimal "actual_paid", precision: 18, scale: 2, default: "0.0"
    t.string "user_fullname"
    t.string "invoice_reference"
    t.date "void_date"
    t.string "void_reason"
    t.string "sync_reference"
    t.decimal "converted_rate", precision: 12, scale: 5, default: "0.0"
    t.string "receipt_type", default: "Payment"
    t.string "reason"
    t.index ["client_id"], name: "index_receipts_on_client_id"
    t.index ["currency_id"], name: "index_receipts_on_currency_id"
    t.index ["device_id", "source_reference"], name: "unique_source_reference_per_device", unique: true
    t.index ["payment_form_id"], name: "index_receipts_on_payment_form_id"
    t.index ["reference_number"], name: "unique_reference_number", unique: true
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "regional_offices", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "region_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_regional_offices_on_region_id"
    t.index ["tenant_id"], name: "index_regional_offices_on_tenant_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "setting_categories", force: :cascade do |t|
    t.string "name"
  end

  create_table "shifts", force: :cascade do |t|
    t.string "shift_id"
    t.string "username"
    t.integer "region_id"
    t.bigint "tenant_id", null: false
    t.bigint "device_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.boolean "active", default: true
    t.boolean "start_shift_synced", default: false
    t.boolean "close_shift_synced", default: false
    t.decimal "declared_amount", precision: 18, scale: 3, default: "0.0"
    t.decimal "cash_collected", precision: 18, scale: 3, default: "0.0"
    t.decimal "total_collected", precision: 18, scale: 3, default: "0.0"
    t.decimal "total_cashed", precision: 18, scale: 3, default: "0.0"
    t.decimal "epayments", precision: 18, scale: 3, default: "0.0"
    t.decimal "usd_epayments", precision: 18, scale: 3, default: "0.0"
    t.decimal "total_prepaid", precision: 18, scale: 3, default: "0.0"
    t.string "shift_supervisor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "district_id", null: false
    t.index ["device_id"], name: "index_shifts_on_device_id"
    t.index ["tenant_id"], name: "index_shifts_on_tenant_id"
  end

  create_table "stock_counts", force: :cascade do |t|
    t.string "product_name", null: false
    t.string "barcode", null: false
    t.integer "quantity", default: 0
    t.date "transaction_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_name", "transaction_date"], name: "unique_products_per_day", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "vat_number"
    t.string "bp_number"
    t.string "address_1", null: false
    t.string "address_2"
    t.string "location"
    t.string "city"
    t.string "country", null: false
    t.string "phone"
    t.string "email"
    t.string "contact_person"
    t.string "contact_mobile"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_suppliers_on_name", unique: true
  end

  create_table "system_modules", force: :cascade do |t|
    t.string "name"
    t.string "description"
  end

  create_table "system_modules_tenants", id: false, force: :cascade do |t|
    t.bigint "system_module_id", null: false
    t.bigint "tenant_id", null: false
  end

  create_table "system_settings", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "config_key_id", null: false
    t.string "config_value"
    t.index ["config_key_id", "tenant_id"], name: "config_key_tenant_unique", unique: true
    t.index ["config_key_id"], name: "index_system_settings_on_config_key_id"
    t.index ["tenant_id"], name: "index_system_settings_on_tenant_id"
  end

  create_table "tarrifs", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.integer "industry_id"
    t.string "name"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_tarrifs_on_tenant_id"
  end

  create_table "tenant_categories", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.index ["name"], name: "index_tenant_categories_on_name", unique: true
  end

  create_table "tenant_locales", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "config_value"
    t.string "config_key"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_tenant_locales_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.bigint "tenant_category_id", null: false
    t.string "company_name"
    t.string "trading_name"
    t.string "registration_number"
    t.string "bp_number"
    t.string "vat_number"
    t.string "address_1"
    t.string "address_2"
    t.string "location"
    t.string "city"
    t.string "country"
    t.string "website"
    t.string "info_email"
    t.string "sales_email"
    t.string "mobile_1"
    t.string "mobile_2"
    t.string "phone_1"
    t.string "phone_2"
    t.string "fax_number"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tenantid"
    t.index ["bp_number"], name: "index_tenants_on_bp_number", unique: true
    t.index ["company_name"], name: "index_tenants_on_company_name", unique: true
    t.index ["registration_number"], name: "index_tenants_on_registration_number", unique: true
    t.index ["tenant_category_id"], name: "index_tenants_on_tenant_category_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.date "transaction_date", null: false
    t.string "reference_number", null: false
    t.string "description", null: false
    t.decimal "amount", precision: 18, scale: 2, default: "0.0"
    t.boolean "debit", default: true
    t.decimal "balance", precision: 18, scale: 2, default: "0.0"
    t.boolean "deleted", default: false
    t.bigint "user_id", null: false
    t.string "source", null: false
    t.integer "source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "journal", default: false
    t.integer "tenant_id", null: false
    t.integer "currency_id", null: false
    t.decimal "rate", precision: 8, scale: 4, default: "1.0", null: false
    t.index ["client_id"], name: "index_transactions_on_client_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "user_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "activity"
    t.datetime "perfomed_at"
    t.string "ipaddress"
    t.string "device_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_targets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "currency", null: false
    t.decimal "targeted_amount", precision: 18, scale: 2, default: "0.0"
    t.decimal "actual_amount", precision: 18, scale: 2, default: "0.0"
    t.integer "invoices_count", default: 0
    t.integer "receipts_count", default: 0
    t.date "transaction_date"
    t.string "month", null: false
    t.string "year", null: false
  end

  create_table "users", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.string "firstname", null: false
    t.string "lastname", null: false
    t.string "role"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "regional_office_id"
    t.string "username", null: false
    t.string "user_fullname"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, where: "(unlock_token IS NOT NULL)"
  end

  create_table "vat_types", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "rate", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "banks", "currencies"
  add_foreign_key "banks", "tenants"
  add_foreign_key "branches", "clients"
  add_foreign_key "branches", "license_categories"
  add_foreign_key "branches", "license_options"
  add_foreign_key "clients", "client_types"
  add_foreign_key "clients", "industries", validate: false
  add_foreign_key "clients", "tenants"
  add_foreign_key "config_keys", "setting_categories"
  add_foreign_key "contact_people", "tenants"
  add_foreign_key "credit_notes", "invoices"
  add_foreign_key "credit_notes", "users"
  add_foreign_key "devices", "regional_offices"
  add_foreign_key "devices", "tenants"
  add_foreign_key "devices", "users"
  add_foreign_key "dump_invoices", "users"
  add_foreign_key "goods_received_items", "goods_receiveds"
  add_foreign_key "goods_received_items", "products"
  add_foreign_key "goods_received_items", "vat_types"
  add_foreign_key "goods_receiveds", "suppliers"
  add_foreign_key "goods_receiveds", "tenants"
  add_foreign_key "goods_receiveds", "users"
  add_foreign_key "invoice_items", "invoices", validate: false
  add_foreign_key "invoices", "banks"
  add_foreign_key "invoices", "clients"
  add_foreign_key "invoices", "currencies"
  add_foreign_key "invoices", "users"
  add_foreign_key "licenses", "clients"
  add_foreign_key "licenses", "invoices"
  add_foreign_key "licenses", "license_categories"
  add_foreign_key "licenses", "license_options"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "measuring_units"
  add_foreign_key "products", "product_categories"
  add_foreign_key "products", "product_types"
  add_foreign_key "products", "vat_types"
  add_foreign_key "quotation_items", "quotations"
  add_foreign_key "quotations", "clients"
  add_foreign_key "quotations", "currencies"
  add_foreign_key "quotations", "users"
  add_foreign_key "receipts", "clients"
  add_foreign_key "receipts", "currencies"
  add_foreign_key "receipts", "payment_forms"
  add_foreign_key "receipts", "users"
  add_foreign_key "regional_offices", "regions"
  add_foreign_key "regional_offices", "tenants"
  add_foreign_key "shifts", "devices"
  add_foreign_key "shifts", "tenants"
  add_foreign_key "system_settings", "config_keys"
  add_foreign_key "system_settings", "tenants"
  add_foreign_key "tarrifs", "tenants"
  add_foreign_key "tenant_locales", "tenants"
  add_foreign_key "tenants", "tenant_categories"
  add_foreign_key "transactions", "clients", validate: false
  add_foreign_key "transactions", "users"
  add_foreign_key "users", "tenants"
end
