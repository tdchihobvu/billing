# Motor vehicles that play music (e.g. buses and kombis) get a vehicle licence disc.
# A client has vehicles; a licence covers chosen vehicles, and one disc prints per vehicle.
class CreateVehicles < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicles do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :registration_number, null: false
      t.string :make_model
      t.string :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :vehicles, %i[tenant_id registration_number], unique: true

    create_table :licenses_vehicles, id: false do |t|
      t.references :license, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
    end
    add_index :licenses_vehicles, %i[license_id vehicle_id], unique: true
  end
end
