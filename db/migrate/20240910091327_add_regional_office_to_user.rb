class AddRegionalOfficeToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :regional_office_id, :integer
  end
end
