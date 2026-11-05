class DeviceSerializer < ActiveModel::Serializer
  attributes :name, :serial_number, :model, :status
  has_one :user
end
