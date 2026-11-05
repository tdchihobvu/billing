class CreateVatTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :vat_types do |t|
      t.string :name, null: false
      t.decimal :rate, precision: 5, scale: 2, default: 0.00

      t.timestamps
    end
  end
end
