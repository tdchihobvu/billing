class CreateDeviceSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :device_settings do |t|
      t.string :device_id, null: false
      t.string :device_token, null: false

    end
  end
end
