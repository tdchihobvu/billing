class CreateRegionalOffices < ActiveRecord::Migration[7.1]
  def change
    create_table :regional_offices do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
