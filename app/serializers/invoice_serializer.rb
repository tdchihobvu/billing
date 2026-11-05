class InvoiceSerializer < ActiveModel::Serializer
  attributes :client_name, :username, :invoiced_on, :invoice_number, :invoice_currency, :license_period, :renewal_date, :expiry_date, :invoice_total, :amount_paid, :balance, :sync_reference
end
