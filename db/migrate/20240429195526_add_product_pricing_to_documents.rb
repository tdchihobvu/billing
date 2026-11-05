class AddProductPricingToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :quotations, :product_pricing, :string, null: false
    add_column :invoices, :product_pricing, :string, null: false
  end
end
