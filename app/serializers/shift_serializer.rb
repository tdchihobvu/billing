class ShiftSerializer < ActiveModel::Serializer
  belongs_to :device
  attributes :shiftId, :username
end
