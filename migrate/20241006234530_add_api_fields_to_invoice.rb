class AddApiFieldsToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :shift_id, :string
    add_column :invoices, :device_id, :integer
    add_column :invoices, :gps_longitude, :string
    add_column :invoices, :gps_latitude, :string
    add_column :invoices, :source_reference, :string
    add_column :invoices, :is_synced, :boolean, default: true
    add_column :invoices, :tenant_id, :integer, null: false
    add_column :receipts, :tenant_id, :integer, null: false
  end
end
