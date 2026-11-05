class CreateTenantLocales < ActiveRecord::Migration[7.1]
  def change
    create_table :tenant_locales do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :config_value
      t.string :config_key
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
