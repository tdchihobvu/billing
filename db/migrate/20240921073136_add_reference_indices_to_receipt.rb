class AddReferenceIndicesToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_index :receipts, [:device_id, :source_reference], unique: true, name: "unique_source_reference_per_device"
    add_index :receipts, [:reference_number], unique: true, name: "unique_reference_number"
  end
end
