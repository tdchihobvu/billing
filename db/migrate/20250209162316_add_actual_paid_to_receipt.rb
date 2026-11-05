class AddActualPaidToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_column :receipts, :actual_paid, :decimal, default: 0.00, precision: 18, scale: 2
    add_column :invoices, :invoice_total, :decimal, default: 0.00, precision: 18, scale: 2
  end
end
