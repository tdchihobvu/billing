class CreateBanks < ActiveRecord::Migration[7.1]
  def change
    create_table :banks do |t|
      t.belongs_to :tenant, null: false, foreign_key: true
      t.string :bank_name, null: false
      t.string :account_name, null: false
      t.string :account_number, null: false
      t.string :branch, null: false
      t.string :swift_code
      t.belongs_to :currency, null: false, foreign_key: true
      t.boolean :active, default: true

    end
  end
end
