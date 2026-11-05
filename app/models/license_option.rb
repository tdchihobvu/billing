class LicenseOption < ApplicationRecord
	has_many :licenses

	scope :active, -> { where(:active => true) }
	
end
