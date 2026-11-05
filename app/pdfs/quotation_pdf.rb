class QuotationPdf < Prawn::Document
	# include ActionView::Helpers::NumberHelper

	def initialize(quotation)
		@quotation = quotation
		text "we are here"
	end

	def quotation_header

	end
end