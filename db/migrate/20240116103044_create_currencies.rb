class CreateCurrencies < ActiveRecord::Migration[7.1]
  def change
    create_table :currencies do |t|
      t.string :name, null: false
      t.string :symbol, null: false
      t.string :origin

    end
    add_index :currencies, :name, unique: true

    Currency.create name: "USD", symbol: "US$", origin: "United States of America"
    Currency.create name: "ZWL", symbol: "ZWL", origin: "Zimbabwe"
  end
end
