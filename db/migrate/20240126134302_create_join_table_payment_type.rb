class CreateJoinTablePaymentType < ActiveRecord::Migration[7.1]
  def change
    create_join_table :currencies, :payment_forms do |t|
      # t.index [:currency_id, :payment_form_id]
      # t.index [:payment_form_id, :currency_id]
    end
  end
end
