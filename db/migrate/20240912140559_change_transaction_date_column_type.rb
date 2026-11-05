class ChangeTransactionDateColumnType < ActiveRecord::Migration[7.1]
  def change
    change_column :receipts, :transaction_date, :datetime
    add_column :receipts, :source_reference, :string, null: false
  end
end
