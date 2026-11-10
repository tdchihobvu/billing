class ReportsController < ApplicationController
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
    @receipts = Receipt.filter(params[:from],params[:to],params[:currency_id],params[:user_id])
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

  def overdue_invoices
    today = Date.current

    scope = Invoice.unpaid
                   .where("due_date < ?", today)
                   .includes(:client, :currency)
                   .order(due_date: :asc, id: :asc)

    respond_to do |format|
      format.html do
        @pagy, @invoices = pagy(scope, limit: 100)
      end

      format.xlsx do
        @invoices = scope
        render xlsx: "overdue_invoices",
               filename: "overdue_invoices.xlsx"
      end
    end
  end

  def upcoming_renewals
    @licenses = License.includes(:client, :invoice).where(expiry_date: Date.today..30.days.from_now).order(:expiry_date)
  end

  private

  def filtering_params(params)
    params.slice(:from, :to, :inspector, :currency_id)
  end  

end
