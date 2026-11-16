# Roles become records a Super admin manages: a name, a description and a set of permissions.
# The six existing roles are created for every company with starting permissions (Role::DEFAULT_PERMISSIONS).
class CreateRoles < ActiveRecord::Migration[7.1]
  def up
    create_table :roles do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.jsonb :permissions, null: false, default: []
      t.boolean :built_in, null: false, default: false
      t.integer :position, null: false, default: 100
      t.timestamps
    end
    add_index :roles, %i[tenant_id key], unique: true

    Role.reset_column_information
    Tenant.find_each { |tenant| Role.ensure_defaults!(tenant) }
  end

  def down
    drop_table :roles
  end
end
