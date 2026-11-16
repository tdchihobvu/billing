# Invoices -> Void requests: Inspectors ask from their phones to void an invoice; someone with
# the "Delete or void invoices" permission approves (the invoice is voided) or rejects (with a reason).
class VoidRequestsController < ApplicationController
  before_action :set_request, only: %i[approve reject]

  def index
    @tab = params[:tab] == "decided" ? "decided" : "waiting"
    @waiting = Notification.waiting_requests(tenant)
    if @tab == "decided"
      @decided = Notification.for_tenant(tenant).where(processed: true).where.not(decision: nil)
                             .order(decided_at: :desc).limit(100).to_a.uniq { |n| [n.process_url, n.decision] }
    end
    invoice_ids = (@waiting + Array(@decided)).filter_map(&:invoice_id)
    @invoices = Invoice.where(tenant_id: tenant.id, id: invoice_ids).preload(:client, :currency, :user).index_by(&:id)
  end

  def approve
    invoice = Invoice.where(tenant_id: tenant.id).find_by(id: @request.invoice_id)
    return reject_missing unless invoice

    if invoice.deleted?
      @request.decide!("approved", by: current_user, note: "The invoice was already void.")
      return redirect_to(void_requests_path, notice: "Invoice #{invoice.invoice_number} was already void. The request is closed.", status: :see_other)
    end

    Invoice.transaction do
      invoice.assign_attributes(deleted: true, void_date: Date.current, void_reason: @request.void_reason.to_s, status: :void)
      # Only the void fields change, so an old validation issue on the invoice must not block it.
      invoice.save!(validate: false)
      @request.decide!("approved", by: current_user, note: params[:note])
    end
    redirect_to void_requests_path, notice: "Invoice #{invoice.invoice_number} was voided. It no longer counts towards balances or reports.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    redirect_to void_requests_path, alert: "Invoice #{invoice&.invoice_number} could not be voided: #{e.record.errors.full_messages.to_sentence}", status: :see_other
  end

  def reject
    reason = params[:note].to_s.strip
    return redirect_to(void_requests_path, alert: "Give a reason for rejecting, so the Inspector knows why.", status: :see_other) if reason.blank?

    @request.decide!("rejected", by: current_user, note: reason)
    number = @request.invoice&.invoice_number
    redirect_to void_requests_path, notice: "Request rejected#{number ? "; invoice #{number} stays as it is" : ''}.", status: :see_other
  end

  private

  def set_request
    @request = Notification.unprocessed.for_tenant(tenant).find(params[:id])
  end

  def reject_missing
    @request.decide!("rejected", by: current_user, note: "The invoice no longer exists.")
    redirect_to void_requests_path, alert: "That invoice no longer exists, so the request was closed.", status: :see_other
  end
end
