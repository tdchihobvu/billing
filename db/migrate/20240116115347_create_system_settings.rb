class CreateSystemSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :system_settings do |t|
      t.belongs_to :tenant, null: false, foreign_key: true
      t.belongs_to :config_key, null: false, foreign_key: true
      t.string :config_value

    end
  end
end
