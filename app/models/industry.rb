class Industry < ApplicationRecord
	belongs_to :tenant
	has_one :tarrif
	validates :name, presence: true, uniqueness: true

	# after_save :create_tariff
	# accepts_nested_attributes_for :tarrif, allow_destroy: true, reject_if: proc { |attributes| attributes['industry_id'].blank? }

	# private

	# def create_tariff
	# 	self.build_tarrif(tenant_id: tenant.id, name: self.name, amount: self.amount)
	# end

end
