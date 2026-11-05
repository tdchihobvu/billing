class CreateTarrifs < ActiveRecord::Migration[7.1]
  def change
    create_table :tarrifs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.integer :industry_id
      t.string :name
      t.decimal :amount

      t.timestamps
    end
  end
end
