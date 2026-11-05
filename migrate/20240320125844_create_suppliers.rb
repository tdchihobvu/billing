class CreateSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :vat_number
      t.string :bp_number
      t.string :address_1, null: false
      t.string :address_2
      t.string :location
      t.string :city
      t.string :country, null: false
      t.string :phone
      t.string :email
      t.string :contact_person
      t.string :contact_mobile
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :suppliers, :name, unique: true
  end
end
