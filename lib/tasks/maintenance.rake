# Data repairs that used to run on every Dashboard visit, across all companies.
# Run them on purpose instead:  bin/rails maintenance:repair
# Back up the database first; the last step deletes licences.
namespace :maintenance do
  desc "Fill missing receipt/invoice/user fields and remove licences whose invoice no longer exists"
  task repair: :environment do
    n = 0
    Receipt.where(actual_paid: 0).find_each { |r| r.update_attribute(:actual_paid, r.amount_paid); n += 1 }
    puts "Receipts: actual_paid filled on #{n}"

    n = 0
    Invoice.where(invoice_total: 0).find_each do |v|
      next if v.invoice_total == v.total
      v.update!(invoice_total: v.total); n += 1
    rescue StandardError => e
      warn "Skipped invoice #{v.id}: #{e.message}"
    end
    puts "Invoices: invoice_total recalculated on #{n}"

    n = 0
    Invoice.where(user_fullname: nil).where.not(user_id: nil).find_each do |i|
      i.update!(user_fullname: i.user.user_fullname); n += 1
    rescue StandardError => e
      warn "Skipped invoice #{i.id}: #{e.message}"
    end
    Receipt.where(user_fullname: nil).where.not(user_id: nil).find_each { |r| r.update_attribute(:user_fullname, r.user.user_fullname); n += 1 }
    User.where(user_fullname: nil).find_each { |u| u.update_attribute(:user_fullname, u.fullname); n += 1 }
    puts "Names filled: #{n}"

    n = 0
    CreditNote.where(tenant_id: nil).find_each { |c| c.update_attribute(:tenant_id, c.user.tenant_id); n += 1 }
    puts "Credit notes: tenant filled on #{n}"

    orphans = License.where.not(invoice_id: Invoice.select(:id))
    puts "Licences without an invoice: #{orphans.count}"
    if ENV["DELETE_ORPHAN_LICENCES"] == "1"
      orphans.find_each(&:destroy)
      puts "Deleted."
    else
      puts "Not deleted. Re-run with DELETE_ORPHAN_LICENCES=1 to delete them."
    end
  end
end
