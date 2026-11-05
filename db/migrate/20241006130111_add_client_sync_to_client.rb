class AddClientSyncToClient < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :gps_latitude, :string
    add_column :clients, :gps_longitude, :string
    add_column :clients, :source_reference, :string
    add_column :clients, :terminal_id, :string
  end
end
