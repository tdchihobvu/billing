class CreateTenantCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :tenant_categories do |t|
      t.string :name
      t.string :description
    end
    TenantCategory.create name: "Default"
    
    add_index :tenant_categories, :name, unique: true
  end
end
