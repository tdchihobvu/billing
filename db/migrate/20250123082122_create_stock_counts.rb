class CreateStockCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_counts do |t|
      t.string :product_name, null: false
      t.string :barcode, null: false
      t.integer :quantity, default: 0
      t.date :transaction_date, null: false

      t.timestamps
    end
    add_index :stock_counts, [:product_name, :transaction_date], unique: true, name: "unique_products_per_day"
  end
end
