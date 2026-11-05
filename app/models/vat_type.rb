class VatType < ApplicationRecord

	def description
		"#{name} (#{rate}%)"
	end
end
