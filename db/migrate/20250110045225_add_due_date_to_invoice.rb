class AddDueDateToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :amount_paid, :decimal, precision: 18, scale: 2, default: 0.00
    add_column :invoices, :due_date, :date
  end
end
