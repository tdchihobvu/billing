class CreatePaymentForms < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_forms do |t|
      t.string :name

      t.timestamps
    end
    PaymentForm.create name: 'Cash'
    PaymentForm.create name: 'Swipe'
    PaymentForm.create name: 'Transfer'
    PaymentForm.create name: 'Ecocash'
    PaymentForm.create name: 'InnBucks'
  end
end
