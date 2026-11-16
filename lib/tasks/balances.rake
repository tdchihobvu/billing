namespace :invoices do
  desc "Report stored receipt and invoice figures that are wrong. APPLY=1 corrects them."
  task recalculate_balances: :environment do
    apply = ENV["APPLY"] == "1"

    receipts_wrong = 0
    Receipt.active.includes(invoice: :currency).find_each do |receipt|
      correct = receipt.amount_paid.to_d.round(2)
      next if receipt.actual_paid.to_d == correct

      receipts_wrong += 1
      receipt.update_column(:actual_paid, correct) if apply
    end

    checked = changed = held = 0
    newly_unpaid = []

    Invoice.active.includes(:license, :currency).find_each do |invoice|
      checked += 1
      if invoice.would_lose_paid_status? && invoice.client_has_unallocated_receipts?
        held += 1
        next
      end

      was_paid = invoice.paid
      invoice.prepare_balance
      unless invoice.balance_needs_saving?
        invoice.restore_attributes
        next
      end

      changed += 1
      newly_unpaid << "#{invoice.invoice_number}: total #{invoice.invoice_total}, received #{invoice.amount_paid}" if was_paid && !invoice.paid
      apply ? invoice.save_prepared_balance : invoice.restore_attributes
    end

    puts "Receipts with a wrong stored figure: #{receipts_wrong}"
    puts "Invoices checked: #{checked}. #{apply ? 'Corrected' : 'Would correct'}: #{changed}."
    puts "Left unchanged, because only the client statement can settle them: #{held}"
    puts "Invoices going from paid to unpaid: #{newly_unpaid.size}"
    puts newly_unpaid.first(20)
    puts "This was a dry run. Run with APPLY=1 to save the corrections." unless apply
  end
end
