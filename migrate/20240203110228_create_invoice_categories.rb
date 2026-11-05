class CreateInvoiceCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :invoice_categories do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
    InvoiceCategory.create name: 'General'
    InvoiceCategory.create name: 'License'
  end
end
