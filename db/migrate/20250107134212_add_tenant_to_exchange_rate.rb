class AddTenantToExchangeRate < ActiveRecord::Migration[7.1]
  def change
    add_column :exchange_rates, :tenant_id, :integer
  end
end
