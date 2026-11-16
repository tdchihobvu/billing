class AddPasswordChangeAndBranchDisplayName < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :must_change_password, :boolean, default: false, null: false
    add_column :branches, :display_name, :string
  end
end
