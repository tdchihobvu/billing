class ExchangeRateSerializer < ActiveModel::Serializer
  attributes :id, :transaction_date, :buying_rate, :midrate, :selling_rate
  has_one :currency
  has_one :user
end
