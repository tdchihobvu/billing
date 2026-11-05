class CreateDistricts < ActiveRecord::Migration[7.1]
  def change
    create_table :districts do |t|
      t.integer :region_id, null: false
      t.string :name, null: false

    end
  end
end
