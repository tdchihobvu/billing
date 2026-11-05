class AddTransactionsFieldsToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_column :receipts, :shift_id, :integer
    add_column :receipts, :device_id, :integer
    add_column :receipts, :gps_longitude, :string
    add_column :receipts, :gps_latitude, :string
    add_column :receipts, :is_synced, :boolean, default: false
    add_column :receipts, :expiry_date, :datetime
    add_column :receipts, :transaction_type_id, :integer
  end
end
