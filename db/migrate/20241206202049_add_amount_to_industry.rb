class AddAmountToIndustry < ActiveRecord::Migration[7.1]
  def change
    add_column :industries, :amount, :decimal, default: 0.00, precision: 18, scale: 2
  end
end
