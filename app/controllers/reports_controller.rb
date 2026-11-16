class ReportsController < ApplicationController
  # Period tabs on the Expiring licences page (the rest stay in the Period select).
  REPORT_TABS = %w[next_30 next_7 next_90 expired_30].freeze

  def index
  end

  def sales
    @users = tenant.users
    if params[:start_date].nil?
      @start_date = Date.today.beginning_of_month
    else
      @start_date = params[:start_date]
    end
    if params[:end_date].nil?
      @end_date = Date.today.end_of_month
    else
      @end_date = params[:end_date]
    end
    @from = params[:start_date]
    @to = params[:end_date]
    @currency = params[:currency_id]
    @user = params[:user_id]
    @page_title = ""
    @page_title << "#{Currency.find(@currency).name} - " if params[:currency_id].present?
    @page_title << "Sales for the Period #{@from.to_date.strftime("%d/%m/%Y")} to #{@to.to_date.strftime("%d/%m/%Y")} " if params[:start_date].present? && params[:end_date].present?
    @page_title << "for #{User.find(@user).user_fullname}" if params[:user_id].present?
    @invoices = Invoice.filter(params[:start_date],params[:end_date],params[:currency_id],params[:user_id],tenant)
    if request.format.html?
      period = Invoice.active.where(tenant_id: tenant.id, invoice_date: @start_date.to_date..@end_date.to_date)
      period = period.where(currency_id: @currency) if @currency.present?
      period = period.where(user_id: @user) if @user.present?
      @currencies = Currency.where(id: period.distinct.pluck(:currency_id)).order(:name)
      # By Inspector: [name, count, {currency_id => total}]
      @by_user = period.group(:user_id, :currency_id).pluck(:user_id, :currency_id, Arel.sql("COUNT(*)"), Arel.sql("SUM(invoice_total)"))
                       .group_by(&:first).map { |uid, rows| [tenant.users.find_by(id: uid)&.fullname.presence || "Unknown", rows.sum { |r| r[2] }, rows.to_h { |r| [r[1], r[3]] }] }
                       .sort_by { |r| -r[1] }
      # By licence category: [name, {currency_id => total}]
      @by_category = License.joins(:invoice, :license_category).merge(period).group("license_categories.name", "invoices.currency_id")
                            .sum(:amount).group_by { |(name, _), _| name }.map { |name, rows| [name, rows.to_h { |(_, cid), t| [cid, t] }] }
                            .sort_by { |_, t| -t.values.sum }
    end
  end

  def vat_sales
    @start_date = params[:start_date].presence || Date.today.beginning_of_month
    @end_date   = params[:end_date].presence || Date.today.end_of_month

    @from = @start_date
    @to   = @end_date

    @invoices = tenant.invoices.sales
                      .where(invoice_date: @start_date..@end_date)

    @invoices = @invoices.where(currency_id: params[:currency_id]) if params[:currency_id].present?
    @invoices = @invoices.where(user_id: params[:user_id]) if params[:user_id].present?
  end

  def collections
    @users = tenant.users
    if params[:from].nil?
      @start_date = Date.today.beginning_of_month
    else
      @start_date = params[:from]
    end
    if params[:to].nil?
      @end_date = Date.today.end_of_month
    else
      @end_date = params[:to]
    end
    @from = params[:from]
    @to = params[:to]
    @currency = params[:currency_id]
    @user = params[:user_id]
    @page_title = ""
    @page_title << "#{Currency.find(@currency).name} - " if params[:currency_id].present?
    @page_title << "Income for the Period #{@from.to_date.strftime("%d/%m/%Y")} to #{@to.to_date.strftime("%d/%m/%Y")} " if params[:from].present? && params[:to].present?
    @page_title << "for #{User.find(@user).user_fullname}" if params[:user_id].present?
    @receipts = Receipt.filter(params[:from],params[:to],params[:currency_id],params[:user_id]).where(tenant_id: tenant.id)
    if request.format.html?
      period = Receipt.active.where(tenant_id: tenant.id, transaction_date: @start_date.to_date..@end_date.to_date)
      period = period.where(currency_id: @currency) if @currency.present?
      period = period.where(user_id: @user) if @user.present?
      @currencies = Currency.where(id: period.distinct.pluck(:currency_id)).order(:name)
      rows = ->(key, names) {
        period.group(key, :currency_id).pluck(key, :currency_id, Arel.sql("COUNT(*)"), Arel.sql("SUM(amount)"))
              .group_by(&:first).map { |id, r| [names[id] || "Unknown", r.sum { |x| x[2] }, r.to_h { |x| [x[1], x[3]] }] }
              .sort_by { |r| -r[1] }
      }
      @by_form = rows.call(:payment_form_id, PaymentForm.pluck(:id, :name).to_h)
      @by_user = rows.call(:user_id, tenant.users.to_h { |u| [u.id, u.fullname.presence || u.username] })
    end
  end

  def collections_by_user
    @users = tenant.users
    @from = params[:from]
    @to = params[:to]
    @currency = params[:currency_id]
    @user = params[:user_id]
    @page_title = ""
    @page_title << "#{Currency.find(@currency).name} - " if params[:currency_id].present?
    @page_title << "Income for the Period #{@from.to_date.strftime("%d/%m/%Y")} to #{@to.to_date.strftime("%d/%m/%Y")} " if params[:from].present? && params[:to].present?
    @page_title << "for #{User.find(@user).user_fullname}" if params[:user_id].present?
    @receipts = Receipt.group_by_user(params[:from],params[:to],params[:currency_id])
  end

  def sales_by_user
    @page_title = "Sales by #{default_user_title}"
    @invoices = Invoice.group_by_user(params[:start_date], params[:end_date], params[:currency_id]).where(tenant_id: tenant.id)
    render xlsx: "sales_by_user", filename: "sales_by_user.xlsx"
  end

  def inspector_report
    @users = tenant.users.order(:firstname, :lastname)
    @start_date = report_date(params[:from]) || Date.current.beginning_of_month
    @end_date = report_date(params[:to]) || Date.current.end_of_month

    @start_date, @end_date = @end_date, @start_date if @start_date > @end_date

    # Proformas are quotes, not invoices raised, so they are left out.
    @invoices = tenant.invoices.sales.where(invoice_date: @start_date..@end_date)
                      .preload(:client, :currency, :user, :invoice_items, license: [:license_category, :license_option])
                      .order(:invoice_date, :invoice_number)
    @receipts = tenant.receipts.active.where(transaction_date: @start_date.beginning_of_day..@end_date.end_of_day)
                      .preload(:client, :currency, :user, :payment_form, :invoice).order(:transaction_date, :reference_number)
    @inspector = tenant.users.find_by(id: params[:user_id]) if params[:user_id].present?
    if @inspector
      @invoices = @invoices.where(user_id: @inspector.id)
      @receipts = @receipts.where(user_id: @inspector.id)
    end
    @show = %w[invoices receipts].include?(params[:show]) ? params[:show] : "all"

    respond_to do |format|
      format.html
      format.xlsx do
        who = @inspector ? @inspector.fullname.parameterize(separator: "_") : "all"
        render xlsx: "inspector_report", filename: "#{default_user_title.to_s.parameterize(separator: "_").presence || "inspector"}_report_#{who}_#{@start_date}_to_#{@end_date}.xlsx"
      end
    end
  end

  # Age bands for overdue invoices: label => [min days overdue, max days overdue].
  OVERDUE_BANDS = {
    "1-30"  => ["1–30 days", 1, 30],
    "31-60" => ["31–60 days", 31, 60],
    "61-90" => ["61–90 days", 61, 90],
    "91-365" => ["91 days – 1 year", 91, 365],
    "365+"  => ["Over a year", 366, nil]
  }.freeze

  def overdue_invoices
    @users = tenant.users.order(:firstname, :lastname)
    @currencies = Currency.order(:name)
    @from = report_date(params[:from])
    @to = report_date(params[:to])
    @band = OVERDUE_BANDS.key?(params[:age]) ? params[:age] : nil
    due = "COALESCE(invoices.due_date, invoices.invoice_date + CAST(#{invoice_validity.to_i} AS integer))"

    # Overdue = a real (non-proforma) invoice, not deleted, unpaid, and past its due date.
    scope = tenant.invoices.sales.where(paid: false).where("invoices.invoice_total > invoices.amount_paid")
                  .where("#{due} < ?", Date.current)
    scope = scope.where(invoice_date: @from..) if @from
    scope = scope.where(invoice_date: ..@to) if @to
    @over = params[:over].to_i.clamp(0, 3650)
    scope = scope.where("#{due} < ?", Date.current - @over) if @over.positive?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(currency_id: params[:currency_id]) if params[:currency_id].present?
    if params[:q].present?
      scope = TextSearch.apply(scope.joins(:client), params[:q], %w[clients.name clients.client_account_number invoices.invoice_number])
    end

    # Counts per age band, for the band chips (before the band filter is applied).
    @band_counts = OVERDUE_BANDS.transform_values do |(_, min, max)|
      band_scope(scope, due, min, max).count
    end
    @all_count = scope.count

    if @band
      _, min, max = OVERDUE_BANDS[@band]
      scope = band_scope(scope, due, min, max)
    end

    ordered = scope.preload(:client, :currency, :user).order(Arel.sql("#{due} ASC"), :invoice_number)
    # Totals over every matching invoice, worked out by the database (the page only shows 100).
    @totals = scope.joins(:currency).group("currencies.name").sum(Arel.sql("invoices.invoice_total - invoices.amount_paid"))
    @count = @band ? @band_counts[@band] : @all_count

    respond_to do |format|
      format.html { @pagy, @invoices = pagy(ordered, limit: 100, count: @count) }
      format.xlsx do
        @invoices = ordered
        render xlsx: "overdue_invoices", filename: "overdue_invoices_#{Date.current}.xlsx"
      end
    end
  end

  # Quick periods for expiring licences: key => [label, first day, last day].
  def self.renewal_periods(today = Date.current)
    {
      "expired_30" => ["Expired in the last 30 days", today - 30, today - 1],
      "next_7"     => ["Next 7 days", today, today + 7],
      "next_30"    => ["Next 30 days", today, today + 30],
      "next_60"    => ["Next 60 days", today, today + 60],
      "next_90"    => ["Next 90 days", today, today + 90],
      "this_month" => ["This month", today.beginning_of_month, today.end_of_month],
      "next_month" => ["Next month", today.next_month.beginning_of_month, today.next_month.end_of_month]
    }
  end

  def upcoming_renewals
    @users = tenant.users.order(:firstname, :lastname)
    @periods = self.class.renewal_periods
    custom_from = report_date(params[:from])
    custom_to = report_date(params[:to])

    if @periods.key?(params[:period])
      @period = params[:period]
      _, @start_date, @end_date = @periods[@period]
    elsif custom_from || custom_to
      @period = "custom"
      @start_date = custom_from || Date.current
      @end_date = custom_to || (@start_date + 30)
    else
      @period = "next_30"
      _, @start_date, @end_date = @periods[@period]
    end
    @start_date, @end_date = @end_date, @start_date if @start_date > @end_date

    base = License.joins(:invoice).where(invoices: { deleted: false, tenant_id: tenant.id })
    base = base.where(invoices: { user_id: params[:user_id] }) if params[:user_id].present?
    scope = base.where(expiry_date: @start_date..@end_date)
    case params[:payment]
    when "paid"   then scope = scope.where(invoices: { status: ["Fully Paid", "Overpaid"] })
    when "unpaid" then scope = scope.where.not(invoices: { status: ["Fully Paid", "Overpaid"] })
    end
    if params[:q].present?
      scope = TextSearch.apply(scope.joins(:client), params[:q], %w[clients.name clients.client_account_number])
      base = TextSearch.apply(base.joins(:client), params[:q], %w[clients.name clients.client_account_number])
    end
    if request.format.html?
      case params[:payment]
      when "paid"   then base = base.where(invoices: { status: ["Fully Paid", "Overpaid"] })
      when "unpaid" then base = base.where.not(invoices: { status: ["Fully Paid", "Overpaid"] })
      end
      @tab_counts = REPORT_TABS.to_h { |key| [key, base.where(expiry_date: @periods[key][1]..@periods[key][2]).count] }
    end

    @licenses = scope.preload(:license_option, client: :branches, invoice: [:user, :currency]).order(:expiry_date)
    @totals = @licenses.group_by { |l| l.invoice.currency.name }
                       .transform_values { |list| list.sum { |l| l.invoice.invoice_total.to_d } }

    respond_to do |format|
      format.html
      format.xlsx { render xlsx: "upcoming_renewals", filename: "expiring_licences_#{@start_date}_to_#{@end_date}.xlsx" }
    end
  end

  private

  def band_scope(scope, due, min, max)
    scope = scope.where("#{due} <= ?", Date.current - min)
    max ? scope.where("#{due} >= ?", Date.current - max) : scope
  end

  def report_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def filtering_params(params)
    params.slice(:from, :to, :inspector, :currency_id)
  end  

end
