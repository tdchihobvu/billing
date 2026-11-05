class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_table :tenants do |t|
      t.belongs_to :tenant_category, null: false, foreign_key: true
      t.string :company_name
      t.string :trading_name
      t.string :registration_number
      t.string :bp_number
      t.string :vat_number
      t.string :address_1
      t.string :address_2
      t.string :location
      t.string :city
      t.string :country
      t.string :website
      t.string :info_email
      t.string :sales_email
      t.string :mobile_1
      t.string :mobile_2
      t.string :phone_1
      t.string :phone_2
      t.string :fax_number
      t.boolean :active, default: false

      t.timestamps
    end

    add_index :tenants, :company_name, unique: true
    add_index :tenants, :registration_number, unique: true
    add_index :tenants, :bp_number, unique: true
    # add_index :tenants, :vat_number, unique: true

  end
end
