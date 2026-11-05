class AddVoidToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :void_date, :date
    add_column :invoices, :void_reason, :string
    add_column :receipts, :void_date, :date
    add_column :receipts, :void_reason, :string
  end
end
