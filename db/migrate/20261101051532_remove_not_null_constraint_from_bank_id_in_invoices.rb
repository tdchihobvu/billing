class RemoveNotNullConstraintFromBankIdInInvoices < ActiveRecord::Migration[7.0]
  def change
    change_column_null :invoices, :bank_id, true
  end
end