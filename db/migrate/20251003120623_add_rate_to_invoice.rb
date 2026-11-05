class AddRateToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :rate, :decimal, default: 0.0000, precision: 12, scale: 5
    add_column :invoices, :converted_rate, :decimal, default: 0.0000, precision: 12, scale: 5
    add_column :receipts, :converted_rate, :decimal, default: 0.0000, precision: 12, scale: 5
  end
end
