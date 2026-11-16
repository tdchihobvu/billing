# System health: a log of problems that used to vanish into server log files, and
# a regular check that every invoice's stored balance matches its receipts.
class CreateSystemHealth < ActiveRecord::Migration[7.1]
  def change
    # Problems worth a person's attention: a payment that could not settle a licence,
    # a page or export that failed, a phone upload the server refused.
    create_table :system_events do |t|
      t.references :tenant, foreign_key: true
      t.references :user, foreign_key: true
      t.string :kind, null: false      # payment_sync, page_error, mobile_upload, balance
      t.string :title, null: false
      t.text :details
      t.string :path
      t.string :record_type
      t.bigint :record_id
      t.datetime :resolved_at
      t.bigint :resolved_by_id
      t.timestamps
    end
    add_index :system_events, %i[tenant_id resolved_at created_at]
    add_index :system_events, :kind

    create_table :balance_check_runs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :user, foreign_key: true  # nil when run by the nightly task
      t.string :status, null: false, default: "running" # running, finished, failed
      t.integer :invoices_checked, null: false, default: 0
      t.integer :issues_found, null: false, default: 0
      t.text :error
      t.datetime :finished_at
      t.timestamps
    end

    create_table :balance_issues do |t|
      t.references :balance_check_run, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.string :kind, null: false # receipts_not_counted, total_wrong, paid_on_account, rounding
      t.decimal :stored_total, precision: 18, scale: 2
      t.decimal :calculated_total, precision: 18, scale: 2
      t.decimal :stored_paid, precision: 18, scale: 2
      t.decimal :calculated_paid, precision: 18, scale: 2
      t.datetime :fixed_at
      t.bigint :fixed_by_id
      t.timestamps
    end
    add_index :balance_issues, %i[balance_check_run_id kind]

    # Admins get the new "system.health" permission, as new Admin roles do by default.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE roles SET permissions = permissions || '["system.health"]'::jsonb
          WHERE key IN ('admin', 'superadmin') AND NOT permissions ? 'system.health'
        SQL
      end
    end
  end
end
