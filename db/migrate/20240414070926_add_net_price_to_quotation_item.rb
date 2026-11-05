class AddNetPriceToQuotationItem < ActiveRecord::Migration[7.1]
  def change
    add_column :quotation_items, :net_price, :decimal, precision: 24, scale: 6, default: 0.000000
  end
end
