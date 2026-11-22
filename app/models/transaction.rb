class Transaction < ApplicationRecord
  belongs_to :client
  belongs_to :user

  scope :active, -> {where(deleted: false)}

  # A journal (take-on balance, credit or debit) changes what the client owes, so their
  # invoices are brought back in line with the statement.
  after_commit :reconcile_client, if: :journal?

  def reconcile_client
    client&.reconcile_invoice_balances
  rescue StandardError => e
    Rails.logger.error("Could not reconcile balances for client #{client_id}: #{e.message}")
  end


  def currency
    Receipt.find(self.source_id).currency.name
  end

  def rated_amount(target_currency)
    amount = self.amount
    #check rate 
    if target_currency.id != self.currency_id
      
      if target_currency.id == base_currency.id
        amount = amount/rate.to_f unless rate.to_f == 0
      else
        amount = amount*rate.to_f unless rate.to_f == 0
      end
    end
    amount
  end
  
end
