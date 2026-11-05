class AddTenantidToTenant < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :tenantid, :string
  end
end
