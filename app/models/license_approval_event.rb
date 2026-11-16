# One step in a licence's approval history: who did what, at which stage, and why.
class LicenseApprovalEvent < ApplicationRecord
  belongs_to :license
  belongs_to :user, optional: true

  LABELS = {
    "queued" => "Fully paid, sent for approval",
    "finance_approved" => "Payment confirmed by Finance",
    "manager_approved" => "Approved by Manager",
    "rejected" => "Rejected",
    "returned" => "Returned to Finance by Manager",
    "resubmitted" => "Sent back for approval",
    "reset" => "Licence details changed, needs approval again"
  }.freeze

  def label
    LABELS.fetch(action, action.humanize)
  end
end
