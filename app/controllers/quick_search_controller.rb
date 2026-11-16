# Finds clients and invoices for the Ctrl+K search box.
class QuickSearchController < ApplicationController
  MINIMUM_TERM_LENGTH = 2
  CLIENT_LIMIT = 6
  INVOICE_LIMIT = 4

  def index
    term = params[:q].to_s.strip
    return render(json: { clients: [], invoices: [] }) if term.length < MINIMUM_TERM_LENGTH

    render json: { clients: matching_clients(term), invoices: matching_invoices(term) }
  end

  private

  def matching_clients(term)
    TextSearch.apply(tenant.clients, term, %w[clients.name clients.trading_name clients.client_account_number])
          .order(Arel.sql("LOWER(TRIM(clients.name))"))
          .limit(CLIENT_LIMIT)
          .map { |client| { label: client.name.strip, detail: "Account #{client.client_account_number}", url: client_path(client) } }
  end

  def matching_invoices(term)
    TextSearch.apply(tenant.invoices.active.joins(:client), term, %w[invoices.invoice_number clients.name])
          .order(invoice_date: :desc)
          .limit(INVOICE_LIMIT)
          .preload(:client)
          .map { |invoice| { label: invoice.invoice_number, detail: invoice.client.name.strip, url: invoice_path(invoice) } }
  end
end
