class CreateJoinTableSystemModuleTenant < ActiveRecord::Migration[7.1]
  def change
    create_join_table :system_modules, :tenants do |t|
      # t.index [:system_module_id, :tenant_id]
      # t.index [:tenant_id, :system_module_id]
    end
  end
end
