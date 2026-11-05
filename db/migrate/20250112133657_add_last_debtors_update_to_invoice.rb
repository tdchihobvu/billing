class AddLastDebtorsUpdateToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :last_debtors_update, :datetime
    add_column :invoices, :last_payment_update, :datetime
    add_column :invoices, :debtors_age, :integer
  end
end
