class CreateQuotations < ActiveRecord::Migration[7.1]
  def change
    create_table :quotations do |t|
      t.belongs_to :client, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.date :quotation_date
      t.string :quotation_number
      t.text :quotation_terms
      t.belongs_to :currency, null: false, foreign_key: true
      t.integer :bank_id
      t.boolean :deleted, default: false

      t.timestamps
    end 
  end
end
