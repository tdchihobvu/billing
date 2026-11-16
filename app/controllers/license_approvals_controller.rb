# The licence approval queue: Finance Officers confirm payment, then a Manager gives final approval.
class LicenseApprovalsController < ApplicationController
  before_action :require_access
  before_action :set_license, only: %i[show approve reject resubmit]

  TABS = {
    "finance" => ["Awaiting Finance", "awaiting_finance"],
    "manager" => ["Awaiting Manager", "awaiting_manager"],
    "rejected" => ["Rejected", "rejected"],
    "approved" => ["Approved", "approved"]
  }.freeze
  PER_PAGE = 50

  def index
    @tab = TABS.key?(params[:tab]) ? params[:tab] : default_tab
    base = tenant_licenses
    if params[:q].present?
      base = TextSearch.apply(base, params[:q], %w[clients.name clients.client_account_number invoices.invoice_number])
    end
    @counts = TABS.transform_values { |(_, status)| base.where(approval_status: status).count }
    # "Approved" lists licences approved through the queue, not the ones approved at go-live.
    @counts["approved"] = base.where(approval_status: "approved").where.not(manager_approved_by_id: nil).count

    scope = base.where(approval_status: TABS[@tab][1])
    scope = @tab == "approved" ? scope.order(manager_approved_at: :desc) : scope.order(:queued_at, :id)
    scope = scope.where.not(manager_approved_by_id: nil) if @tab == "approved" # recent approvals, not the go-live batch
    @count = scope.count
    @page = [params[:page].to_i, 1].max
    @pages = [(@count / PER_PAGE.to_f).ceil, 1].max
    @licenses = scope.preload(:license_category, :license_option, :finance_approver, :rejecter, client: [], invoice: [:currency, :user])
                     .offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def show
    @events = @license.approval_events.includes(:user)
  end

  def approve
    if @license.approval_status == "awaiting_finance"
      @license.finance_approve!(current_user, note: params[:note], payment_confirmed: params[:payment_confirmed] == "1")
      notice = "Payment confirmed. #{@license.client.name}'s licence now waits for the Manager's final approval."
    else
      @license.manager_approve!(current_user, note: params[:note])
      notice = "Approved. #{@license.client.name}'s licence can now be printed."
    end
    redirect_to next_path, notice: notice, status: :see_other
  rescue LicenseApproval::Error, ActiveRecord::RecordInvalid => e
    redirect_to license_approval_path(@license), alert: e.message, status: :see_other
  end

  def reject
    stage = @license.approval_status
    @license.reject!(current_user, reason: params[:reason])
    notice = stage == "awaiting_manager" ? "Returned to Finance with your reason." : "Rejected. Finance can send it back for approval once the problem is fixed."
    redirect_to next_path, notice: notice, status: :see_other
  rescue LicenseApproval::Error, ActiveRecord::RecordInvalid => e
    redirect_to license_approval_path(@license), alert: e.message, status: :see_other
  end

  def resubmit
    @license.resubmit!(current_user, note: params[:note])
    redirect_to license_approval_path(@license), notice: "Sent back to the Finance queue.", status: :see_other
  rescue LicenseApproval::Error, ActiveRecord::RecordInvalid => e
    redirect_to license_approval_path(@license), alert: e.message, status: :see_other
  end

  private

  def require_access
    return if current_user.sees_license_approvals?

    redirect_to root_path, alert: "Your role can't open licence approvals. Ask a Super admin if you need it."
  end

  def tenant_licenses
    License.joins(:client, :invoice).where(invoices: { tenant_id: tenant.id, deleted: false })
  end

  def set_license
    @license = tenant_licenses.find(params[:id])
  end

  # Each person lands on the stage they work on.
  def default_tab
    return "manager" if current_user.final_approver? && !current_user.finance_officer?
    "finance"
  end

  # After acting, go back to the queue the request came from.
  def next_path
    license_approvals_path(tab: params[:return_tab].presence_in(TABS.keys) || default_tab)
  end
end
