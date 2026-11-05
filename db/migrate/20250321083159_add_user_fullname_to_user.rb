class AddUserFullnameToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :user_fullname, :string
  end
end
