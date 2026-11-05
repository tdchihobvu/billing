class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.belongs_to :client, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.date :invoice_date
      t.string :invoice_number
      t.integer :device_id
      t.belongs_to :currency, null: false, foreign_key: true
      t.belongs_to :bank, null: false, foreign_key: true
      t.boolean :deleted, default: false
      t.boolean :is_proforma, default: false
      t.boolean :sent, default: false
      t.boolean :paid, default: false

      t.timestamps
    end
    add_index :invoices, [:invoice_number, :is_proforma, :device_id, :deleted], unique: true, name: "invoice_number_unique"
  end
end
