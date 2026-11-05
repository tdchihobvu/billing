class AddCodesToCurrency < ActiveRecord::Migration[7.1]
  def change
    add_column :currencies, :active, :boolean, default: true
    add_column :currencies, :trcode, :string
    add_column :currencies, :account_reference, :string
  end
end
