class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :regional_office, null: false, foreign_key: true
      t.string :name, null: false
      t.string :terminal_id, null: false
      t.string :serial_number, null: false
      t.string :model
      t.boolean :active, default: false
      t.references :user, null: false, foreign_key: true
      t.text :access_token

      t.timestamps
    end

    add_index :devices, :terminal_id, unique: true, name: "unique_terminal_id"
    add_index :devices, :serial_number, unique: true, name: "unique_serial_number"
  end
end
