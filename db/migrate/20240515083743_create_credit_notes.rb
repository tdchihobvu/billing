class CreateCreditNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_notes do |t|
      t.references :invoice, null: false, foreign_key: true
      t.datetime :transaction_date, null: false
      t.string :document_number, null: false
      t.string :reference_number, null: false
      t.text :reason, null: false
      t.decimal :invoice_amount, default: 0.0000, precision: 18, scale: 4
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :credit_notes, [:document_number, :reference_number], unique: true, name: "unique_invoice_reference"
  end
end
