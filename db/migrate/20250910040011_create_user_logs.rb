class CreateUserLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :user_logs do |t|
      t.bigint :user_id, null: false
      t.text :activity
      t.datetime :perfomed_at
      t.string :ipaddress
      t.string :device_name

      t.timestamps
    end
  end
end
