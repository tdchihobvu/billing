class MakeClientNameUnique < ActiveRecord::Migration[7.1]
  def change
    remove_index :clients,
                 name: "index_clients_on_name_and_tenant_id"

    add_index :clients,
              [:tenant_id, :name],
              name: "index_clients_on_tenant_id_and_name",
              unique: true
  end
end

