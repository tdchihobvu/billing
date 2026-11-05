class AddIsParentToLicense < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :is_parent, :boolean, default: true
    add_column :licenses, :quantity, :integer, default: 1
    add_column :licenses, :amount, :decimal, scale: 2, precision: 18, default: 0.00
  end
end
