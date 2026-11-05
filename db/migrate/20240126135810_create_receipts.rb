class CreateReceipts < ActiveRecord::Migration[7.1]
  def change
    create_table :receipts do |t|
      t.belongs_to :client, null: false, foreign_key: true
      t.belongs_to :currency, null: false, foreign_key: true
      t.belongs_to :payment_form, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.date :transaction_date, null: false
      t.string :reference_number, null: false
      t.decimal :amount, precision: 18, scale: 2, default: 0.00 
      t.decimal :rate, precision: 18, scale: 4, default: 0.00 
      t.string :description, null: false
      t.boolean :deleted, default: false
      t.integer :invoice_id

      t.timestamps
    end
    # add_index :receipts, [:reference_number, :client_id], unique: true, name: "unique receipt number"
  end
end
