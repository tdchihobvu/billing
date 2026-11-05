class AddBalanceBfToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :balance_bf, :decimal, default: 0.00, scale: 2, precision: 18
    add_column :clients, :bf_currency_id, :integer
  end
end
