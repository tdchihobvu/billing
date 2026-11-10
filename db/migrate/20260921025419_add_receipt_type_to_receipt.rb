class AddReceiptTypeToReceipt < ActiveRecord::Migration[7.1]
  def change
    add_column :receipts, :receipt_type, :string, default: 'Payment'
    add_column :receipts, :reason, :string
  end
  # PaymentForm.find_or_create_by(name: 'Setoff', is_setoff: true)
  # PaymentForm.find_or_create_by(name: 'Write off', is_setoff: true)
end
