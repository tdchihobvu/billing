class AddIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :system_settings, [:config_key_id, :tenant_id], unique: true, name: "config_key_tenant_unique"
    add_index :invoice_items, [:description, :invoice_id], unique: true, name: "invoice_item_unique"
  end
end
