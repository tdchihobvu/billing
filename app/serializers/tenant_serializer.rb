class TenantSerializer < ActiveModel::Serializer
  attributes :company_name, :address_1, :address_2, :location, :city, :country, :mobile_1, :phone_1, :phone_2, :sales_email, :website
end
