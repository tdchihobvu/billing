class GoodsReceived < ApplicationRecord
  belongs_to :supplier
  belongs_to :user
  belongs_to :tenant
  has_many :goods_received_items

  accepts_nested_attributes_for :goods_received_items, allow_destroy: true, reject_if: proc { |attributes| attributes['description'].blank? }

end
