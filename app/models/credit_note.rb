class CreditNote < ApplicationRecord
  belongs_to :invoice  
  belongs_to :user

  before_validation :populate_invoice_details

  validates :invoice_id, :transaction_date, :document_number, :reference_number, :reason, :user_id, presence: true

  private

  def populate_invoice_details
    if invoice_id.nil?
      errors.add(:invoice_id, "Please select Invoice to Credit.")
    else
      self.reference_number = invoice.invoice_number
      self.invoice_amount = invoice.total
    end
  end
end
