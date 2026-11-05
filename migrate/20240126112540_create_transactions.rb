class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :client, null: false, foreign_key: true
      t.date :transaction_date, null: false
      t.string :reference_number, null: false
      t.string :description, null: false
      t.decimal :amount, precision: 18, scale: 2, default: 0.00
      t.boolean :debit, default: true
      t.decimal :balance, precision: 18, scale: 2, default: 0.00
      t.boolean :deleted, default: false
      t.references :user, null: false, foreign_key: true
      t.string :source, null: false
      t.integer :source_id, null: false

      t.timestamps
    end
  end
end
