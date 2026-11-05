class AccountStatementPdf < Prawn::Document
	include ActionView::Helpers::NumberHelper

	def initialize(tenant,client,logo_path,from,end_date)
		@currency = Currency.find(client.currency_id)
		@target_currency = @currency
		super(:bottom_margin => 40)
		@client = client
		@last_row = @client.transactions.active.size
		@as_at = end_date
		image "#{Rails.root}/public/tenant_logo/#{logo_path}", height: 100

		bounding_box([400,720], width: 330, height: 110, :pad => 2) do 
			move_down 8
			indent(0, 15) do # left and right padding
			  text "#{tenant.company_name}", size: 10, style: :bold
			end
			move_down 5
			indent 0,0 do
			  text "#{tenant.address_1}", align: :left, size: 9
			  unless tenant.address_2.nil?
			    text "#{tenant.address_2}", align: :left, size: 9
			  end
			  text "#{tenant.location}", align: :left, size: 9
			  text "#{tenant.city}, #{tenant.country}", align: :left, size: 9
			  text "T: #{tenant.phone_1}, #{tenant.mobile_1}", align: :left, size: 9
			  text "E: #{tenant.sales_email}", align: :left, size: 9
			  move_down 3
			  indent(0,0) do # left and right padding
				text "VAT Number: #{tenant.vat_number}", size: 9, style: :bold
				text "TIN Number: #{tenant.bp_number}", size: 9, style: :bold
			  end
			end
		end
		move_down 3
		stroke_horizontal_rule
		move_down 20
		text "Account Statement", align: :center, size: 18, style: :bold
		move_down 17
		invoice_details = [
			["Statement Date:","#{end_date.strftime("%d/%m/%Y")}"],
			["Period:","#{from.strftime("%d/%m/%Y")} - #{end_date.strftime("%d/%m/%Y")}"],
			["No. of Invoices:","#{@client.transactions.where(source: 'Invoices', deleted: false).size}"],
			["Balance:","#{number_to_currency(@client.account_balance_as_at(@as_at,@target_currency), unit: "#{@client.default_currency} ")}"]
		]
		table(invoice_details, :column_widths => [80, 100], :cell_style => { :borders => [], :padding => 0, :size => 9 }, :position => :right)

		bounding_box([0,560], width: 200, height: 95, :pad => 2) do 
			move_down 5
			fill_color "056CA1"
			text "Customer Details", align: :left, size: 9
			fill_color "222222"
			move_down 3
			text "#{client.name.upcase}", align: :left, size: 9, style: :bold
			# stroke_horizontal_rule
			indent 0,0 do
			  text "#{client.address_1}", align: :left, size: 9
			  unless client.address_2.nil?
			    text "#{client.address_2}", align: :left, size: 9
			  end
			  text "#{client.location}", align: :left, size: 9
			  text "#{client.city}, #{client.country}", align: :left, size: 9
			end
		end
		font_size 9
		line_transactions
	end

	def line_transactions
		table line_transaction_rows do		
			style(row(0..-1), :borders => [:left,:right,:top,:bottom], :border_color => "DDDDDD")
			# style(rows(last_row), :padding => [2,2,2], :borders => [:left,:right, :bottom], font_style: :bold)
			style(rows(@last_row.to_i-1), :padding => 3, font_style: :bold, size: 9)
			style(row(1..-1), :padding => 4)
			style(row([0,@last_row.to_i]), :font_style => :bold, :borders => [], :padding => 5)
			row([0,@last_row.to_i]).background_color = '014269'
			row([0,@last_row.to_i]).text_color = 'FFFFFF'
			# columns(0).text_color = 'DDE9E9'
			style(columns([0]), :width => 43, :align => :left)
			style(columns([1]), :width => 62, :align => :left)
			# style(columns([2]), :width => 180, :align => :right)
			style(columns([3]), :width => 60, :align => :right)
			style(columns([4]), :width => 60, :align => :right)
			style(columns([5]), :width => 60, :align => :right)
			self.width = 540
			self.row_colors = ["DDE9E9","ffffff"]
			self.header = true
			self.position = :center
		end
		# table(line_transaction_rows, :cell_style => { :borders => [], :header => true}, :row_colors => ["dddddd","ffffff"], 
		# 	:column_widths => {0 => 400,1 => 70,2 => 70} )
	end

	def line_transaction_rows
		total = 0
		balance = 0
		[["Date","INV/REF#","Description","Debit","Credit","Balance"]] +
		@client.transactions.order(transaction_date: :asc, debit: :desc).where("transaction_date <= '#{@as_at}' AND deleted = false").order('transaction_date Asc').map do |transaction|
			total += 1
			if transaction.debit?
				balance += transaction.rated_amount(@target_currency)
            	[transaction.transaction_date.strftime("%d/%m/%y"),transaction.reference_number,"Invoice - #{transaction.description}",number_to_currency(transaction.rated_amount(@target_currency), unit: ""),"",number_to_currency(balance, unit: "")]
            else
            	balance -= transaction.rated_amount(@target_currency)
            	[transaction.transaction_date.strftime("%d/%m/%y"),transaction.reference_number,"Receipt - #{transaction.description} (#{transaction.currency})","",number_to_currency(transaction.rated_amount(@target_currency), unit: ""),number_to_currency(balance, unit: "")]
        	end
        end +

        [["","","Account Current Balance #{@client.default_currency}",number_to_currency(@client.debits_total_as_at(@as_at,@target_currency), unit: ""),number_to_currency(@client.credits_total_as_at(@as_at,@target_currency), unit: ""),number_to_currency(@client.account_balance_as_at(@as_at,@target_currency), unit: "")]]

	end


end