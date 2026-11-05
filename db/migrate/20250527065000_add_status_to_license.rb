class AddStatusToLicense < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :status, :string, null: false, default: 'Not Paid'
  end
end
