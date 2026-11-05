class CreateGoodsReceivedItems < ActiveRecord::Migration[7.1]
  def change
    create_table :goods_received_items do |t|
      t.belongs_to :product, null: false, foreign_key: true
      t.belongs_to :goods_received, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :net_cost, precision: 18, scale: 4, default: 0.0000
      t.decimal :cost_vat, precision: 18, scale: 4, default: 0.0000
      t.decimal :cost, precision: 18, scale: 4, default: 0.0000
      t.decimal :quantity, precision: 8, scale: 3, default: 0.0000
      t.decimal :net_total_cost, precision: 18, scale: 4, default: 0.0000
      t.decimal :total_vat, precision: 18, scale: 4, default: 0.0000
      t.decimal :total_cost, precision: 18, scale: 4, default: 0.0000
      t.decimal :net_selling_price, precision: 18, scale: 4, default: 0.0000
      t.decimal :selling_price, precision: 18, scale: 4, default: 0.0000
      t.belongs_to :vat_type, null: false, foreign_key: true      
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
