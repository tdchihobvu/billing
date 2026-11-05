class AddDiscountToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :discount, :decimal, precision: 15, scale: 2, default: 0.00
    add_column :invoices, :subtotal, :decimal, precision: 15, scale: 2, default: 0.00
    add_column :invoices, :vat_amount, :decimal, precision: 15, scale: 2, default: 0.00
  end
end
