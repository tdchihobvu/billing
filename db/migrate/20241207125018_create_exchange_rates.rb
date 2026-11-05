class CreateExchangeRates < ActiveRecord::Migration[7.1]
  def change
    create_table :exchange_rates do |t|
      t.integer :currency_id, null: false
      t.date :transaction_date, null: false
      t.decimal :buying_rate, precision: 12, scale: 5, null: false
      t.decimal :midrate, precision: 12, scale: 5, null: false
      t.decimal :selling_rate, precision: 12, scale: 5, null: false
      t.decimal :alternative_rate, precision: 12, scale: 5, null: false
      t.integer :user_id, null: false

      t.timestamps
    end
    add_index :exchange_rates, [:currency_id, :transaction_date], unique: true, name: 'unique_currency_rates'
  end
end
