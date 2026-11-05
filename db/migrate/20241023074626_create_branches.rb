class CreateBranches < ActiveRecord::Migration[7.1]
  def change
    create_table :branches do |t|
      t.references :client, null: false, foreign_key: true
      t.integer :tenant_id, null: false
      t.string :name, null: false
      t.string :address_1, null: false
      t.string :address_2
      t.string :location, null: false
      t.string :city
      t.string :country
      t.references :license_category, null: false, foreign_key: true
      t.references :license_option, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :branches, [:name, :client_id, :tenant_id], unique: true, name: "unique_client_branches"
  end
end
