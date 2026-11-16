class ReceiptSerializer < ActiveModel::Serializer
  attributes :client_name, :username, :receipt_number, :receipt_date, :amount, :currency_used, :rate, :payment_method, :description, :invoice_reference, :sync_reference

  # Website receipts have no mobile references, so use the invoice and receipt numbers.
  def invoice_reference
    object.invoice_reference.presence || object.invoice&.sync_reference
  end

  def sync_reference
    object.sync_reference.presence || object.reference_number
  end
end
