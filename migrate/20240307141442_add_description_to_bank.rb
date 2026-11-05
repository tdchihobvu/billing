class AddDescriptionToBank < ActiveRecord::Migration[7.1]
  def change
    add_column :banks, :description, :string, null: false
  end
end
