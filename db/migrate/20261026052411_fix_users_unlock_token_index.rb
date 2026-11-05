class FixUsersUnlockTokenIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, name: "index_users_on_unlock_token"

    add_index :users, :unlock_token, unique: true,
              where: "unlock_token IS NOT NULL"
  end
end
