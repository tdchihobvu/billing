class AddStatusToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :status, :string, null: false, default: 'Not Paid'
    add_column :invoices, :last_status_update, :datetime

    x = 0
    Invoice.active.where('last_status_update IS NULL').each do |i|
      i.update_invoice_status
      puts("#{x+=1} of #{Invoice.active.size} dealt with #{i.invoice_number}")
    end
  end
end
