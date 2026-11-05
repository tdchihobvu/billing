class Transaction < ApplicationRecord
  belongs_to :client
  belongs_to :user

  scope :active, -> {where(deleted: false)}


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
