class AddPaidToLicense < ActiveRecord::Migration[7.1]
  def change
    add_column :licenses, :paid, :boolean, default: false
  end
end
