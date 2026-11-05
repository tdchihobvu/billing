class CreateLicenses < ActiveRecord::Migration[7.1]
  def change
    create_table :licenses do |t|
      t.belongs_to :client, null: false, foreign_key: true
      t.string :license_key
      t.belongs_to :license_category, null: false, foreign_key: true
      t.date :renewal_date, null: false
      t.date :expiry_date, null: false
      t.boolean :auto_renewal, default: true
      t.belongs_to :license_option, null: false, foreign_key: true
      t.integer :printed, default: 0
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
