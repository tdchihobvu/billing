# A request from an Inspector's phone to void an invoice. Decided on Invoices -> Void requests.
# A phone may send the same request more than once; copies share the same process_url and
# are shown and decided together.
class Notification < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :decider, class_name: "User", foreign_key: :processed_by, optional: true

  scope :unprocessed, -> { where(processed: false) }
  scope :for_tenant, ->(tenant) { joins(:user).where(users: { tenant_id: tenant.id }) }

  # Waiting requests for a company, one per invoice (repeats collapsed, even if the reason
  # was typed differently), oldest first.
  def self.waiting_requests(tenant)
    unprocessed.for_tenant(tenant).order(:created_at, :id).to_a.uniq(&:group_key)
  end

  def group_key
    invoice_id ? "invoice:#{invoice_id}" : "id:#{id}"
  end

  # This request and every other waiting request for the same invoice (decided together).
  def copies
    return Notification.where(id: id) unless invoice_id

    same = Notification.unprocessed.where(user_id: User.where(tenant_id: user&.tenant_id).select(:id))
                       .where("process_url LIKE ?", "%void_invoice?id=#{invoice_id}&%").pluck(:id)
    Notification.where(id: same | [id])
  end

  # The invoice and reason are carried in the request's link (…/void_invoice?id=3210&void_reason=…).
  def link_params
    @link_params ||= Rack::Utils.parse_query(URI.parse(process_url.to_s).query.to_s)
  rescue URI::InvalidURIError
    {}
  end

  def invoice_id
    link_params["id"].presence&.to_i
  end

  def void_reason
    link_params["void_reason"].presence || message.to_s[/\(([^)]*)\)\s*\z/, 1]
  end

  def invoice
    @invoice ||= Invoice.find_by(id: invoice_id) if invoice_id
  end

  def decide!(decision, by:, note: nil)
    copies.update_all(processed: true, read: true, processed_by: by.id, decision: decision,
                      decided_at: Time.current, decision_note: note.to_s.strip.presence, updated_at: Time.current)
  end
end
