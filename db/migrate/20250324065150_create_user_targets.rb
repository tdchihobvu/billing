class CreateUserTargets < ActiveRecord::Migration[7.1]
  def change
    create_table :user_targets do |t|
      t.bigint :user_id, null: false
      t.bigint :currency, null: false
      t.decimal :targeted_amount, precision: 18, scale: 2, default: 0.00
      t.decimal :actual_amount, precision: 18, scale: 2, default: 0.00
      t.integer :invoices_count, default: 0
      t.integer :receipts_count, default: 0
      t.date :transaction_date
      t.string :month, null: false
      t.string :year, null: false

    end
  end
end
