class CreateJoinTableBranchInvoice < ActiveRecord::Migration[7.1]
  def change
    create_join_table :branches, :invoices do |t|
      # t.index [:branch_id, :invoice_id]
      # t.index [:invoice_id, :branch_id]
    end
  end
end
