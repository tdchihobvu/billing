class Currency < ApplicationRecord
	has_and_belongs_to_many :payment_forms

	scope :active, -> {where("name NOT IN('USD')")}
	scope :non_base, -> {where("name NOT IN('USD')")}

end
