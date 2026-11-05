class UserSerializer < ActiveModel::Serializer
  attributes :id, :firstname, :lastname, :role, :email, :username, :password
end
