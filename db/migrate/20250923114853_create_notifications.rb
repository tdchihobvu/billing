class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.string :message
      t.boolean :read, default: false
      t.integer :processed_by
      t.string :process_url
      t.boolean :processed, default: false
      t.integer :user_id, null: false

      t.timestamps
    end
  end
end
