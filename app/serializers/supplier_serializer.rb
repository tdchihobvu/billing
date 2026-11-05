class SupplierSerializer < ActiveModel::Serializer
  attributes :id, :name, :vat_number, :bp_number, :address_1, :address_2, :location, :country, :phone, :email, :contact_person, :contact_mobile, :active
end
