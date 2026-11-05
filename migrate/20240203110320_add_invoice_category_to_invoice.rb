class AddInvoiceCategoryToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :invoice_category_id, :integer
    add_column :invoices, :license, :boolean, default: false
  end
end
