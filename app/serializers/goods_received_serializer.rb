class GoodsReceivedSerializer < ActiveModel::Serializer
  attributes :id, :grv_number, :ext_number, :date_received, :deleted
  has_one :supplier
  has_one :user
end
