class SystemSetting < ApplicationRecord
  belongs_to :tenant
  belongs_to :config_key

  validates :config_key_id, uniqueness: { scope: [:tenant_id], message: " already exists!" }
end
