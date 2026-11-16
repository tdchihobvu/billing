namespace :statements do
  desc "Hide statement lines for deleted or voided invoices and receipts (and show restored ones again)"
  task sync_deleted: :environment do
    before = Transaction.where(deleted: [false, nil], journal: [false, nil])
                        .where("(source = 'Invoices' AND source_id IN (SELECT id FROM invoices WHERE deleted = true)) OR " \
                               "(source = 'Receipts' AND source_id IN (SELECT id FROM receipts WHERE deleted = true))").count
    client_ids = Transaction.where(journal: [false, nil]).distinct.pluck(:client_id).compact
    Client.where(id: client_ids).find_each(&:sync_deleted_statement_lines)
    puts "Statement lines hidden for deleted invoices/receipts: #{before} (checked #{client_ids.size} clients)"
  end
end
