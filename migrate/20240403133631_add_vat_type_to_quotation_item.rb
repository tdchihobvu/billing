class AddVatTypeToQuotationItem < ActiveRecord::Migration[7.1]
  def change
    add_column :quotation_items, :vat_type_id, :integer, null: false
    add_column :invoice_items, :vat_type_id, :integer, null: false
  end
end
