# Administration -> System health: problems the system logged, and the balance check.
# Access: the "system.health" permission (Super admins always; Admins by default).
class SystemHealthController < ApplicationController
  TABS = %w[problems balances].freeze

  def index
    @tab = TABS.include?(params[:tab]) ? params[:tab] : "problems"
    events = SystemEvent.where(tenant_id: [tenant.id, nil])
    @open_count = events.open.count
    @kind_counts = events.open.group(:kind).count

    @show = params[:show] == "resolved" ? "resolved" : "open"
    scope = @show == "resolved" ? events.where.not(resolved_at: nil) : events.open
    scope = scope.where(kind: params[:kind]) if SystemEvent::KINDS.key?(params[:kind])
    @events = scope.recent.preload(:user).limit(200)

    @run = BalanceCheckRun.where(tenant_id: tenant.id).latest_first.first
    @last_finished = BalanceCheckRun.where(tenant_id: tenant.id, status: "finished").latest_first.first
    if @last_finished
      issues = @last_finished.issues
      @issue_counts = issues.group(:kind).count
      @open_fixable = issues.open.fixable.count
      @issue_kind = BalanceIssue::KINDS.key?(params[:issue]) ? params[:issue] : "receipts_not_counted"
      @open_in_kind = issues.open.where(kind: @issue_kind).count
      @issues = issues.where(kind: @issue_kind).preload(invoice: [:client, :currency]).order(:fixed_at, :id).limit(300)
    end
  end

  def resolve
    event = SystemEvent.where(tenant_id: [tenant.id, nil]).find(params[:id])
    event.resolve!(current_user)
    redirect_to system_health_path(tab: "problems"), notice: "Marked as dealt with.", status: :see_other
  end

  def resolve_all
    kind = SystemEvent::KINDS.key?(params[:kind]) ? params[:kind] : nil
    scope = SystemEvent.where(tenant_id: [tenant.id, nil]).open
    scope = scope.where(kind: kind) if kind
    n = scope.update_all(resolved_at: Time.current, resolved_by_id: current_user.id)
    redirect_to system_health_path(tab: "problems"), notice: "#{n} #{'problem'.pluralize(n)} marked as dealt with.", status: :see_other
  end

  def check_balances
    run = BalanceCheckRun.start!(tenant, user: current_user)
    redirect_to system_health_path(tab: "balances"),
                notice: run.created_at > 5.seconds.ago ? "Balance check started. It takes about a minute; this page updates when it's done." : "A balance check is already running.",
                status: :see_other
  end

  def fix_issue
    issue = BalanceIssue.where(tenant_id: tenant.id).find(params[:id])
    fixed = issue.fix!(current_user)
    message = fixed ? "Invoice #{issue.invoice.invoice_number} was recalculated from its receipts." :
                      "Invoice #{issue.invoice.invoice_number} could not be corrected automatically. Open it and check its receipts and statement."
    redirect_to system_health_path(tab: "balances", issue: issue.kind), (fixed ? :notice : :alert) => message, status: :see_other
  end

  def fix_all
    run = BalanceCheckRun.where(tenant_id: tenant.id, status: "finished").latest_first.first
    kind = BalanceIssue::NEEDS_FIX.include?(params[:issue]) ? params[:issue] : nil
    return redirect_to(system_health_path(tab: "balances"), alert: "Choose a kind of difference to fix.") unless run && kind

    fixed = failed = 0
    run.issues.open.where(kind: kind).preload(:invoice).find_each { |i| i.fix!(current_user) ? fixed += 1 : failed += 1 }
    note = failed.positive? ? " #{failed} could not be corrected automatically and are left for review." : ""
    redirect_to system_health_path(tab: "balances", issue: kind), notice: "#{fixed} #{'invoice'.pluralize(fixed)} recalculated.#{note}", status: :see_other
  end
end
