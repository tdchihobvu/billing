class AddTenantToIndustry < ActiveRecord::Migration[7.1]
  def change
    add_column :industries, :tenant_id, :integer
  end
end
