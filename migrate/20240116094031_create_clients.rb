class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|

      t.belongs_to :tenant, foreign_key: true, null: false
      t.belongs_to :client_type, null: false, foreign_key: true
      t.belongs_to :industry, null: false, foreign_key: true
      t.string :name, null: false
      t.string :trading_name
      t.string :bp_number
      t.string :vat_number
      t.string :address_1, null: false
      t.string :address_2
      t.string :location
      t.string :city, null: false
      t.string :country, null: false
      t.string :website
      t.string :mobile
      t.string :phone, null: false
      t.string :email, null: false
      t.string :cp_name, null: false
      t.string :cp_mobile, null: false
      t.string :cp_email
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :clients, [:name, :tenant_id], unique: true
  end
end
