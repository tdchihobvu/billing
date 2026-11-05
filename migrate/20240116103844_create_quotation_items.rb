class CreateQuotationItems < ActiveRecord::Migration[7.1]
  def change
    create_table :quotation_items do |t|
      t.belongs_to :quotation, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :quantity, default: 1
      t.decimal :unit_price, precision: 18, scale: 4, default: 0.00 
      t.decimal :vat, precision: 18, scale: 4, default: 0.00 
      t.decimal :line_total, precision: 18, scale: 4, default: 0.00 
      t.decimal :line_vat, precision: 18, scale: 4, default: 0.00 
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end