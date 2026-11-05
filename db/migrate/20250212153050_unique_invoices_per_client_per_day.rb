class UniqueInvoicesPerClientPerDay < ActiveRecord::Migration[7.1]
  def change
    add_index :invoices, [:invoice_date, :client_id, :invoice_total, :deleted], unique: true, name: "unique_invoice_per_client"
  end
end
