class Notification < ApplicationRecord
	
	scope :unprocessed, -> {where(processed: false)}
end
