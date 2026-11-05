class AddClientAccountNumberToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :client_account_number, :string, null: false

    add_index :clients, [:tenant_id, :client_account_number], unique: true, name: "account_numbers_unique"
  end

end
