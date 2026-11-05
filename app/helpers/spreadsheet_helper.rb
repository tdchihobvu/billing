module SpreadsheetHelper

	def format_date(date)
		date.strftime("%d/%m/%Y")
	end

	def format_amount(amount)
		# number_with_delimiter(amount, delimiter: ",")
		number_to_currency(amount, unit: " ")
	end
end