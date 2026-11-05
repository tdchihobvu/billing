namespace :invoices do

	desc "Check receipts without invoice ids"
	task receipts_without_invoice_ids: :environment do
		Receipt.active.where(invoice_id: nil).order(user_id: :asc, transaction_date: :asc).find_each.with_index(1) do |receipt, index|
		  puts "#{index} *** #{receipt.transaction_date},#{receipt.amount},#{receipt.rate},#{receipt.invoice_reference},#{receipt&.user&.user_fullname}"

		  if (invoice = Invoice.find_by(source_reference: receipt.invoice_reference, user_id: receipt.user_id))
		    puts ">>>>>>>>>> #{invoice.invoice_number}"
		    receipt.update!(invoice: invoice)
		  end
		end
	end

	desc "Check invoices balances"
	task check_invoice_balances: :environment do
		invoices = Invoice.active
		invoices.each_with_index do |invoice,i|
			puts("#{i+=1},#{invoice.id},#{invoice.currency.name},#{invoice.invoice_number},#{invoice.total},#{invoice.total_paid}")
			invoice.receipts.each do |r|
				puts("***** #{r.receipt_number},#{r.amount},#{r.currency&.name},#{r.rate}")
			end
			invoice.update_balance
		end
	end

end