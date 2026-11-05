class LicenseSerializer < ActiveModel::Serializer
  attributes :id, :renewal_date, :expiry_date, :auto_renewal, :printed, :active
  has_one :client
  has_one :license_category
  has_one :license_option
end
