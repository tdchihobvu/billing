# One run of the balance check: compares every active invoice's stored total and amount
# paid with what its items and receipts add up to, using the same calculation that runs
# when a receipt is saved, and records each difference as a BalanceIssue.
class BalanceCheckRun < ApplicationRecord
  belongs_to :tenant
  belongs_to :user, optional: true
  has_many :issues, class_name: "BalanceIssue", dependent: :delete_all

  # Differences smaller than this are currency-conversion rounding, not errors.
  ROUNDING = 0.05

  scope :latest_first, -> { order(created_at: :desc) }

  def self.start!(tenant, user: nil)
    running = where(tenant_id: tenant.id, status: "running").where("created_at > ?", 15.minutes.ago).first
    return running if running

    run = create!(tenant: tenant, user: user)
    BalanceCheckJob.perform_later(run.id)
    run
  end

  def running?
    status == "running"
  end

  def perform!
    checked = 0
    found = []
    tenant.invoices.active.preload(:license, :currency, receipts: [:currency, { invoice: :currency }]).find_each do |inv|
      checked += 1
      kind = classify(inv)
      next unless kind

      found << { balance_check_run_id: id, tenant_id: tenant_id, invoice_id: inv.id, kind: kind,
                 stored_total: inv.invoice_total.to_d.round(2), calculated_total: @total,
                 stored_paid: inv.amount_paid.to_d.round(2), calculated_paid: @paid,
                 created_at: Time.current, updated_at: Time.current }
    end
    BalanceIssue.insert_all(found) if found.any?
    update!(status: "finished", invoices_checked: checked, issues_found: found.count { |f| BalanceIssue::NEEDS_FIX.include?(f[:kind]) },
            finished_at: Time.current)
    record_event
  rescue StandardError => e
    update_columns(status: "failed", error: e.message.truncate(1000), finished_at: Time.current)
    SystemEvent.record(kind: "balance", title: "The balance check stopped with an error", details: e.message, tenant_id: tenant_id)
  end

  private

  def classify(inv)
    @total = inv.total.to_d.round(2)
    @paid = inv.total_amount_paid.to_d.round(2)
    total_diff = (inv.invoice_total.to_d.round(2) - @total).abs
    paid_diff = (inv.amount_paid.to_d.round(2) - @paid).abs
    return nil if total_diff <= 0.01 && paid_diff <= 0.01

    if total_diff > ROUNDING then "total_wrong"
    elsif paid_diff <= ROUNDING then "rounding"
    elsif inv.amount_paid.to_d > @paid && Receipt.active.where(client_id: inv.client_id, invoice_id: nil).exists?
      "paid_on_account" # settled through the client's statement, not its own receipts: correct as it is
    else
      "receipts_not_counted"
    end
  end

  def record_event
    return if issues_found.zero?

    SystemEvent.record(kind: "balance", tenant_id: tenant_id,
                       title: "#{issues_found} #{'invoice'.pluralize(issues_found)} with a stored balance that doesn't match its receipts",
                       details: "Found by the balance check of #{finished_at.strftime('%d %b %Y %H:%M')}. Open System health, Balance check, to review and fix them.")
  end
end
