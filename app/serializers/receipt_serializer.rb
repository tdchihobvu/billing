class ReceiptSerializer < ActiveModel::Serializer
  attributes :client_name, :username, :receipt_number, :receipt_date, :amount, :currency_used, :rate, :payment_method, :description, :invoice_reference, :sync_reference
end
