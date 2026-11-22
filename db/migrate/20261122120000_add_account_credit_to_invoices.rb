# Money a client paid on account (receipts with no invoice, credit journals) that the
# statement counts against this invoice. Kept apart from the invoice's own receipts so
# both can be shown, and recalculated whenever the client's account changes.
class AddAccountCreditToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :account_credit, :decimal, precision: 18, scale: 2, default: "0.0", null: false
  end
end
