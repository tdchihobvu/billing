class AddPrefixToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :prefix, :string
  end
end
