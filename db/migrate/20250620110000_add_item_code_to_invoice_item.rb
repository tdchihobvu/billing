class AddItemCodeToInvoiceItem < ActiveRecord::Migration[7.1]
  def change
    add_column :invoice_items, :item_code, :string
  end
end
