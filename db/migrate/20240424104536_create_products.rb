
class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :description
      t.string :barcode
      t.references :product_category, null: false, foreign_key: true
      t.references :product_type, null: false, foreign_key: true
      t.references :brand, null: false, foreign_key: true
      t.references :measuring_unit, null: false, foreign_key: true
      t.references :vat_type, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :products, [:barcode, :name], unique: true
  end
end