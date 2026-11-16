# Figures for the Dashboard, for one company only. Read-only: building this never writes.
# Amounts are in the company's base currency (USD); other currencies are converted
# at each document's own rate, the same way client statements do it.
class DashboardSummary
  Todo = Struct.new(:tone, :icon, :title, :detail, :action, :path, keyword_init: true)
  Mate = Struct.new(:id, :name, :initials, :invoiced, :collected, keyword_init: true)

  attr_reader :tenant, :today, :month_start, :base

  def initialize(tenant, today: Date.current, validity_days: 7, frequency: "weekly")
    @tenant = tenant
    @today = today
    @month_start = today.beginning_of_month
    @validity_days = validity_days.to_i
    @frequency = frequency
    @base = Currency.find_by(name: "USD")
  end

  def month_invoices
    @month_invoices ||= tenant.invoices.sales.where(invoice_date: month_start..today).to_a
  end

  def month_receipts
    @month_receipts ||= tenant.receipts.active.where(transaction_date: month_start.beginning_of_day..today.end_of_day).to_a
  end

  # How much of this month's invoices has already been paid. Receipts this month can be larger
  # than invoices this month (older debts paid), so this is the honest "collected" share.
  def month_paid
    @month_paid ||= month_invoices.reject(&:void?).sum { |i| to_base_invoice(i, i.amount_paid) }
  end

  def invoiced
    @invoiced ||= month_invoices.reject(&:void?).sum { |i| to_base_invoice(i) }
  end

  def collected
    @collected ||= month_receipts.sum { |r| to_base_receipt(r) }
  end

  def collected_pct
    invoiced.positive? ? [(month_paid / invoiced * 100).round, 100].min : 0
  end

  def overdue_scope
    due = "COALESCE(invoices.due_date, invoices.invoice_date + CAST(#{@validity_days} AS integer))"
    tenant.invoices.sales.where(paid: false).where("invoices.invoice_total > invoices.amount_paid").where("#{due} < ?", today)
  end

  def overdue_total
    @overdue_total ||= overdue_scope.joins(:currency).group("currencies.name").sum(Arel.sql("invoices.invoice_total - invoices.amount_paid"))
  end

  def overdue_base
    overdue_total.fetch("USD", 0).to_d
  end

  def todos(void_requests:, license_approvals: 0)
    list = []
    if license_approvals.positive?
      list << Todo.new(tone: "m", icon: "fa-stamp", title: "#{license_approvals} #{'licence'.pluralize(license_approvals)} waiting for your approval",
                       detail: "Paid licences can't be printed until they are approved", action: "Licence approvals", path: :approvals)
    end
    due = "COALESCE(invoices.due_date, invoices.invoice_date + CAST(#{@validity_days} AS integer))"
    over30 = overdue_scope.where("#{due} < ?", today - 30)
    n30 = over30.count
    if n30.positive?
      usd = over30.joins(:currency).where(currencies: { name: "USD" }).sum(Arel.sql("invoices.invoice_total - invoices.amount_paid"))
      clients = over30.distinct.count(:client_id)
      list << Todo.new(tone: "r", icon: "fa-clock", title: "#{n30} #{'invoice'.pluralize(n30)} more than 30 days overdue",
                       detail: "#{ActiveSupport::NumberHelper.number_to_currency(usd, unit: 'USD ')} across #{clients} #{'client'.pluralize(clients)}",
                       action: "Review list", path: :overdue)
    end
    expiring = License.joins(:invoice).where(invoices: { deleted: false, tenant_id: tenant.id }, expiry_date: today..(today + 7)).count
    if expiring.positive?
      list << Todo.new(tone: "s", icon: "fa-stamp", title: "#{expiring} #{'licence'.pluralize(expiring)} expire in the next 7 days",
                       detail: "Remind the clients before they lapse", action: "Expiring licences", path: :expiring)
    end
    if void_requests.positive?
      list << Todo.new(tone: "m", icon: "fa-bell", title: "#{void_requests} void #{'request'.pluralize(void_requests)} waiting",
                       detail: "Sent from the mobile app", action: "Decide", path: :notifications)
    end
    rate = ExchangeRate.where(tenant_id: tenant.id).order(transaction_date: :desc).first
    if rate && @frequency.to_s.downcase == "weekly"
      left = (rate.transaction_date.to_date + 7 - today).to_i
      if left <= 2
        list << Todo.new(tone: "s", icon: "fa-exchange-alt", title: "Exchange rate expires #{left <= 0 ? 'today' : "in #{left} #{'day'.pluralize(left)}"}",
                         detail: "Set on #{rate.transaction_date.strftime('%d %b')}. ZWL receipts need a valid rate.", action: "Exchange rates", path: :rates)
      end
    end
    on_account = tenant.receipts.active.where(invoice_id: nil, transaction_date: (today - 30).beginning_of_day..today.end_of_day)
    n = on_account.count
    if n.positive?
      list << Todo.new(tone: "g", icon: "fa-money-bill", title: "#{n} #{'receipt'.pluralize(n)} not linked to an invoice",
                       detail: "In the last 30 days", action: "View receipts", path: :receipts)
    end
    list
  end

  def inspectors(limit: 6)
    inv = month_invoices.reject(&:void?).group_by(&:user_id).transform_values { |l| l.sum { |i| to_base_invoice(i) } }
    rec = month_receipts.group_by(&:user_id).transform_values { |l| l.sum { |r| to_base_receipt(r) } }
    ids = (inv.keys | rec.keys).compact
    users = User.where(id: ids).index_by(&:id)
    ids.map do |id|
      u = users[id]
      next unless u
      Mate.new(id: u.id, name: u.fullname, initials: [u.firstname, u.lastname].compact.map { |x| x[0] }.join.upcase, invoiced: inv.fetch(id, 0), collected: rec.fetch(id, 0))
    end.compact.sort_by { |m| -m.invoiced }.first(limit)
  end

  # Collections per month for the last six months, in base currency.
  def collections_by_month
    start = (today - 5.months).beginning_of_month
    receipts = tenant.receipts.active.where(transaction_date: start.beginning_of_day..today.end_of_day).preload(:currency).to_a
    (0..5).map do |k|
      m = start + k.months
      [m.strftime("%b"), receipts.select { |r| r.transaction_date.to_date.beginning_of_month == m }.sum { |r| to_base_receipt(r) }]
    end
  end

  private

  def to_base_invoice(invoice, amount = invoice.invoice_total)
    return amount.to_d if base.nil? || invoice.currency_id == base.id
    invoice.rate.to_f.positive? ? amount.to_d / invoice.rate.to_d : 0.to_d
  end

  def to_base_receipt(receipt)
    return receipt.amount.to_d if base.nil? || receipt.currency_id == base.id
    receipt.rate.to_f.positive? ? receipt.amount.to_d / receipt.rate.to_d : 0.to_d
  end
end
