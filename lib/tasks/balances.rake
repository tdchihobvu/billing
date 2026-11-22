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

  desc "Bring every client's invoice balances in line with their statement. APPLY=1 saves; TENANT=id limits it."
  task reconcile_with_statements: :environment do
    apply = ENV["APPLY"] == "1"
    clients = Client.all
    clients = clients.where(tenant_id: ENV["TENANT"]) if ENV["TENANT"].present?
    ids = clients.joins(:invoices).merge(Invoice.sales).distinct.pluck(:id)

    snapshot = -> { Invoice.sales.where(client_id: ids).pluck(:id, :amount_paid, :paid).to_h { |id, paid, done| [id, [paid.to_d, done]] } }
    before = snapshot.call
    failed = []
    started = Time.current

    work = lambda do
      ids.each_with_index do |id, i|
        ActiveRecord::Base.transaction(requires_new: true) { Client.find(id).reconcile_invoice_balances }
      rescue StandardError => e
        failed << "#{id}: #{e.message}"
      ensure
        print "\r#{i + 1} of #{ids.size} clients" if ((i + 1) % 100).zero? || i + 1 == ids.size
      end
      puts
    end

    # A real run saves client by client; a dry run does the same work inside one transaction and undoes it.
    work.call if apply
    ActiveRecord::Base.transaction do
      work.call unless apply

      after = snapshot.call
      changed = after.count { |id, figs| before[id] && before[id][0] != figs[0] }
      now_paid = after.count { |id, figs| before[id] && !before[id][1] && figs[1] }
      now_unpaid = after.count { |id, figs| before[id] && before[id][1] && !figs[1] }
      puts "Clients: #{ids.size}. Invoices whose amount paid changed: #{changed}."
      puts "Now shown paid: #{now_paid}. Now shown unpaid (their receipts and the statement don't cover them): #{now_unpaid}."
      unpaid_ids = after.select { |id, figs| before[id] && before[id][1] && !figs[1] }.keys
      Invoice.where(id: unpaid_ids).includes(:client).each do |inv|
        puts "  now unpaid: #{inv.invoice_number} #{inv.client&.name.to_s.squish} total #{inv.invoice_total.to_f} paid #{inv.amount_paid.to_f}"
      end
      puts "Clients that could not be done: #{failed.size}", failed.first(20) if failed.any?
      skipped = SystemEvent.where(kind: "payment_sync").where("created_at > ?", started).count
      puts "Invoices skipped and flagged in System health (e.g. duplicates): #{skipped}" if skipped.positive?

      unless apply
        puts "This was a dry run; nothing was saved. Run with APPLY=1 to save."
        raise ActiveRecord::Rollback
      end
    end
  end
end
