class ClientSerializer < ActiveModel::Serializer
  attributes :client_account_number, :name, :business_nature, :address_1, :address_2, :location, :city, :country, :phone, :email, :contact_person
end
