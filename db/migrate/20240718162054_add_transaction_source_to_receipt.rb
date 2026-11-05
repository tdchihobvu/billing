class AddTransactionSourceToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_column :receipts, :transaction_source, :string, null: false
    add_column :receipts, :transaction_source_id, :integer
    add_column :receipts, :business_nature, :string
  end
end
