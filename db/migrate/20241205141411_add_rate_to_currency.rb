class AddRateToCurrency < ActiveRecord::Migration[7.1]
  def change
    add_column :currencies, :rate, :decimal, precision: 12, scale: 5, default: 0.00000
  end
end
