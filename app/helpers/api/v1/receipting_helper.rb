module Api::V1::ReceiptingHelper
	
	def default_currency
		Currency.find_by(name: 'USD')
	end

	def get_rate(currency,transaction_date)
		12300.56
	end
end
