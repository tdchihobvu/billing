class GoodsReceivedItem < ApplicationRecord
  belongs_to :product
  belongs_to :vat_type
  belongs_to :goods_received
end
