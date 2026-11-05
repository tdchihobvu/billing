class AddClientTotalsToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :total_invoices, :decimal, precision: 18, scale: 2, default: 0.00
    add_column :clients, :total_receipts, :decimal, precision: 18, scale: 2, default: 0.00
    add_column :clients, :balance, :decimal, precision: 18, scale: 2, default: 0.00
    add_column :clients, :last_statement_update, :datetime
  end
end
