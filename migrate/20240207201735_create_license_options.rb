class CreateLicenseOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :license_options do |t|
      t.string :name, null: false
      t.integer :months, default: 1
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
