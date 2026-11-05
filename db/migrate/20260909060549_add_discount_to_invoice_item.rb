class AddDiscountToInvoiceItem < ActiveRecord::Migration[7.1]
  def change
    add_column :invoice_items, :discount, :decimal, precision: 15, scale: 2, default: 0.00
  end
end
