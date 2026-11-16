# Approval workflow for licences.
#
#   pending_payment --(fully paid)--> awaiting_finance --(Finance confirms payment)--> awaiting_manager
#   awaiting_manager --(Manager approves)--> approved   (only now can the licence be printed)
#   awaiting_finance --(Finance rejects)--> rejected --(Finance resubmits)--> awaiting_finance
#   awaiting_manager --(Manager rejects)--> awaiting_finance (returned, with the reason)
#
# Finance Officers handle the first stage; Managers (or a Super admin as backup) the second.
# Nobody may approve both stages of the same licence.
module LicenseApproval
  extend ActiveSupport::Concern

  STATUSES = %w[pending_payment awaiting_finance awaiting_manager approved rejected].freeze
  STATUS_LABELS = {
    "pending_payment" => "Waiting for payment",
    "awaiting_finance" => "Awaiting Finance",
    "awaiting_manager" => "Awaiting Manager",
    "approved" => "Approved",
    "rejected" => "Rejected"
  }.freeze
  # Changing these after approval means the approved licence is no longer what was approved.
  MATERIAL_FIELDS = %w[license_category_id license_option_id renewal_date expiry_date amount quantity special_days invoice_id client_id].freeze
  # Payment tolerance used elsewhere in the system when deciding a licence is paid.
  PAID_TOLERANCE = 0.5

  class Error < StandardError; end

  included do
    has_many :approval_events, -> { order(:created_at, :id) }, class_name: "LicenseApprovalEvent", dependent: :delete_all
    belongs_to :finance_approver, class_name: "User", foreign_key: :finance_approved_by_id, optional: true
    belongs_to :manager_approver, class_name: "User", foreign_key: :manager_approved_by_id, optional: true
    belongs_to :rejecter, class_name: "User", foreign_key: :rejected_by_id, optional: true

    validates :approval_status, inclusion: { in: STATUSES }

    scope :awaiting_finance, -> { where(approval_status: "awaiting_finance") }
    scope :awaiting_manager, -> { where(approval_status: "awaiting_manager") }
    scope :approval_queue, -> { where(approval_status: %w[awaiting_finance awaiting_manager]) }

    before_save :queue_when_paid
    before_save :reset_approval_on_material_change
    after_save :record_pending_event
  end

  def printable?
    approval_status == "approved"
  end

  def approval_label
    STATUS_LABELS.fetch(approval_status, approval_status.to_s.humanize)
  end

  def approval_tone
    { "approved" => "paid", "awaiting_finance" => "part", "awaiting_manager" => "part", "rejected" => "late" }.fetch(approval_status, "")
  end

  # What a user sees instead of a print button.
  def approval_hint
    case approval_status
    when "pending_payment" then "Prints once fully paid and approved."
    when "awaiting_finance" then "Waiting for a Finance Officer to confirm payment."
    when "awaiting_manager" then "Waiting for the Manager's final approval."
    when "rejected" then "Rejected: #{rejection_reason}"
    end
  end

  # Balance still owed on the licence's invoice (what Finance must confirm is zero).
  def invoice_balance
    return 0.to_d if invoice.nil?
    (invoice.invoice_total.to_d - invoice.amount_paid.to_d).round(2)
  end

  def fully_paid_invoice?
    invoice.present? && invoice_balance <= PAID_TOLERANCE
  end

  # ---------------------------------------------------------------- permissions
  def finance_can_act?(user)
    approval_status == "awaiting_finance" && user&.finance_officer?
  end

  def manager_can_act?(user)
    approval_status == "awaiting_manager" && user&.final_approver? && user.id != finance_approved_by_id
  end

  def can_resubmit?(user)
    approval_status == "rejected" && (user&.finance_officer? || user&.superadmin?)
  end

  # ---------------------------------------------------------------- actions
  def finance_approve!(user, note: nil, payment_confirmed: false)
    raise Error, "This licence is not waiting for Finance." unless approval_status == "awaiting_finance"
    raise Error, "Only a Finance Officer can confirm payment." unless user&.finance_officer?
    raise Error, "Tick the box to confirm that full payment was received." unless payment_confirmed
    raise Error, "The invoice still has #{format('%.2f', invoice_balance)} outstanding. Approve once it is fully paid." unless fully_paid_invoice?

    transaction do
      update!(approval_status: "awaiting_manager", finance_approved_by_id: user.id, finance_approved_at: Time.current,
              rejected_by_id: nil, rejected_at: nil, rejected_stage: nil, rejection_reason: nil)
      log_event!("finance_approved", user, "finance", note)
    end
  end

  def manager_approve!(user, note: nil)
    raise Error, "This licence is not waiting for final approval." unless approval_status == "awaiting_manager"
    raise Error, "Only a Manager (or a Super admin) can give final approval." unless user&.final_approver?
    raise Error, "You confirmed the payment, so someone else must give final approval." if user.id == finance_approved_by_id

    transaction do
      update!(approval_status: "approved", manager_approved_by_id: user.id, manager_approved_at: Time.current)
      log_event!("manager_approved", user, "manager", note)
    end
  end

  def reject!(user, reason:)
    raise Error, "Give a reason for rejecting." if reason.to_s.strip.blank?

    if finance_can_act?(user)
      transaction do
        update!(approval_status: "rejected", rejected_by_id: user.id, rejected_at: Time.current,
                rejected_stage: "finance", rejection_reason: reason.strip)
        log_event!("rejected", user, "finance", reason)
      end
    elsif manager_can_act?(user)
      # A Manager's rejection goes back to Finance with the reason.
      transaction do
        update!(approval_status: "awaiting_finance", finance_approved_by_id: nil, finance_approved_at: nil,
                rejected_by_id: user.id, rejected_at: Time.current, rejected_stage: "manager", rejection_reason: reason.strip)
        log_event!("returned", user, "manager", reason)
      end
    else
      raise Error, "You can't reject this licence at its current stage."
    end
  end

  def resubmit!(user, note: nil)
    raise Error, "Only a rejected licence can be sent back for approval." unless approval_status == "rejected"
    raise Error, "Only a Finance Officer can send it back for approval." unless can_resubmit?(user)

    transaction do
      update!(approval_status: "awaiting_finance", queued_at: Time.current)
      log_event!("resubmitted", user, "finance", note)
    end
  end

  private

  def log_event!(action, user, stage, note)
    approval_events.create!(action: action, user_id: user&.id, stage: stage, note: note.to_s.strip.presence, created_at: Time.current)
  end

  # A licence that becomes fully paid joins the Finance queue automatically.
  def queue_when_paid
    return unless paid? && approval_status == "pending_payment"

    self.approval_status = "awaiting_finance"
    self.queued_at ||= Time.current
    @pending_event = "queued"
  end

  # An approved (or half-approved) licence whose details change must be approved again.
  def reset_approval_on_material_change
    return if new_record?
    return unless %w[awaiting_manager approved].include?(approval_status_in_database)
    return unless (changed & MATERIAL_FIELDS).any?

    self.approval_status = paid? ? "awaiting_finance" : "pending_payment"
    self.queued_at = Time.current if paid?
    self.finance_approved_by_id = self.finance_approved_at = nil
    self.manager_approved_by_id = self.manager_approved_at = nil
    @pending_event = "reset"
  end

  def record_pending_event
    action = @pending_event
    @pending_event = nil
    return unless action

    approval_events.create!(action: action, stage: "finance", created_at: Time.current)
  end
end
