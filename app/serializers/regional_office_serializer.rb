class RegionalOfficeSerializer < ActiveModel::Serializer
  attributes :id, :name
  has_one :region
end
