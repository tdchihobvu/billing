class AddIsSetoffToPaymentForm < ActiveRecord::Migration[7.1]
  def change
    add_column :payment_forms, :is_setoff, :boolean, default: false
  end
end
