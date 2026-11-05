class AddSpecialDaysToLicense < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :special_days, :integer, default: 1
    add_column :licenses, :is_special, :boolean, default: false
  end
end
