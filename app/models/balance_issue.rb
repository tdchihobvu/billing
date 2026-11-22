# An invoice whose stored figures did not match its items and receipts at a balance check.
class BalanceIssue < ApplicationRecord
  belongs_to :balance_check_run
  belongs_to :tenant
  belongs_to :invoice

  KINDS = {
    "receipts_not_counted" => ["Receipts not counted", "Its receipts add up to a different amount paid than the invoice shows.", "late"],
    "total_wrong" => ["Invoice total wrong", "The stored total differs from what the invoice's lines add up to.", "late"],
    "rounding" => ["Rounding only", "A difference of a few cents from currency conversion.", ""],
    "paid_on_account" => ["Paid on account", "Settled through the client's statement rather than its own receipts. This is correct; nothing to fix.", "paid"]
  }.freeze
  # Kinds that are real errors and can be fixed by recalculating.
  NEEDS_FIX = %w[receipts_not_counted total_wrong rounding].freeze

  scope :open, -> { where(fixed_at: nil) }
  scope :fixable, -> { where(kind: NEEDS_FIX) }

  def label = KINDS.dig(kind, 0) || kind.humanize
  def explanation = KINDS.dig(kind, 1)
  def tone = KINDS.dig(kind, 2) || ""

  # Recalculates the invoice's stored figures from its items and receipts.
  # Uses the same safe correction as the rest of the system: an invoice paid through
  # the statement is never turned back to unpaid.
  def fix!(by)
    return false unless NEEDS_FIX.include?(kind)

    inv = invoice
    changed = inv.sync_balance
    inv.client&.reconcile_invoice_balances # counts money paid on account, as the statement does
    inv.reload
    still_off = (inv.invoice_total.to_d.round(2) - inv.total.to_d.round(2)).abs > 0.01 ||
                (inv.amount_paid.to_d.round(2) - inv.total_amount_paid.to_d.round(2)).abs > 0.01
    return false if still_off && !changed

    update!(fixed_at: Time.current, fixed_by_id: by&.id)
    true
  end
end
