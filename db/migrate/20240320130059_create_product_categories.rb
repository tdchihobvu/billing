class CreateProductCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :product_categories do |t|
      t.string :name, null: false
      t.integer :parent_id

      t.timestamps
    end
    add_index :product_categories, [:name, :parent_id], unique: true
  end
end
