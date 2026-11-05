class TenantCategory < ApplicationRecord
	validates :name, uniqueness: true, presence: true
end
