class TenantLocaleSerializer < ActiveModel::Serializer
  attributes :id, :config_value, :config_key, :active
end
