class AddAvailableToDevice < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :available, :boolean, default: true
  end
end
