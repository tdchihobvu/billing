class AddInvoiceReferenceToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_column :receipts, :invoice_reference, :string
  end
end
