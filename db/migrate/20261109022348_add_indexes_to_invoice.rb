class AddIndexesToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_index :invoices, :invoice_date
    add_index :invoices, :last_debtors_update
  end
end
