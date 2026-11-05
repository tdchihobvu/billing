class CreateJoinTableBankInvoice < ActiveRecord::Migration[7.1]
  def change
    create_join_table :banks, :invoices do |t|
      # t.index [:bank_id, :invoice_id]
      # t.index [:invoice_id, :bank_id]
    end
  end
end
