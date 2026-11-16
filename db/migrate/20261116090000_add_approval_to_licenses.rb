# Licences can no longer be printed straight after payment. A fully paid licence joins a
# queue: a Finance Officer confirms the payment, then a Manager gives final approval.
class AddApprovalToLicenses < ActiveRecord::Migration[7.1]
  def up
    change_table :licenses, bulk: true do |t|
      # pending_payment, awaiting_finance, awaiting_manager, approved, rejected
      t.string :approval_status, null: false, default: "pending_payment"
      t.datetime :queued_at
      t.bigint :finance_approved_by_id
      t.datetime :finance_approved_at
      t.bigint :manager_approved_by_id
      t.datetime :manager_approved_at
      t.bigint :rejected_by_id
      t.datetime :rejected_at
      t.string :rejected_stage
      t.text :rejection_reason
    end
    add_index :licenses, :approval_status

    create_table :license_approval_events do |t|
      t.references :license, null: false, foreign_key: true
      t.bigint :user_id
      t.string :action, null: false # queued, finance_approved, manager_approved, rejected, returned, resubmitted, reset
      t.string :stage
      t.text :note
      t.datetime :created_at, null: false
    end

    # Go-live rule agreed on 2026-11-16: licences already fully paid stay printable.
    execute <<~SQL
      UPDATE licenses SET approval_status = 'approved', manager_approved_at = NOW()
      WHERE paid = TRUE
    SQL
  end

  def down
    drop_table :license_approval_events
    remove_index :licenses, :approval_status
    change_table :licenses, bulk: true do |t|
      t.remove :approval_status, :queued_at, :finance_approved_by_id, :finance_approved_at,
               :manager_approved_by_id, :manager_approved_at, :rejected_by_id, :rejected_at,
               :rejected_stage, :rejection_reason
    end
  end
end
