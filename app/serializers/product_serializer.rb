class ProductSerializer < ActiveModel::Serializer
  attributes :id, :code, :name, :description, :active
  has_one :product_category
  has_one :product_type
  has_one :vat_type
end
