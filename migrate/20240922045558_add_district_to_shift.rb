class AddDistrictToShift < ActiveRecord::Migration[7.1]
  def change
    add_column :shifts, :district_id, :integer, null: false
  end
end
