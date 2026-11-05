class AddCurrencyIdToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :currency_id, :integer, default: 1
  end
end
