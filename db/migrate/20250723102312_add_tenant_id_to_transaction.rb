class AddTenantIdToTransaction < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :tenant_id, :integer, null: false
    add_column :transactions, :currency_id, :integer, null: false
    add_column :transactions, :rate, :decimal, default: 1, scale: 4, precision: 8, null: false
  end
end
