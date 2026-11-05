class CreateGoodsReceiveds < ActiveRecord::Migration[7.1]
  def change
    create_table :goods_receiveds do |t|
      t.string :grv_number, null: false
      t.string :ext_number
      t.belongs_to :supplier, null: false, foreign_key: true
      t.belongs_to :tenant, null: false, foreign_key: true
      t.date :date_received, null: false
      t.belongs_to :user, null: false, foreign_key: true
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
