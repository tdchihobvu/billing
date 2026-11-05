class AddSyncReferenceToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_column :receipts, :sync_reference, :string
  end
end
