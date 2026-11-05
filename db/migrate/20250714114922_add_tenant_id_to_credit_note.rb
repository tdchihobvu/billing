class AddTenantIdToCreditNote < ActiveRecord::Migration[7.1]
  def change
    add_column :credit_notes, :tenant_id, :integer
  end
end
