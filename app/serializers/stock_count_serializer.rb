class StockCountSerializer < ActiveModel::Serializer
  attributes :id, :product_name, :quantity, :transaction_date
end
