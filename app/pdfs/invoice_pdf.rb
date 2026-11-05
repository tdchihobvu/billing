class InvoicePdf < Prawn::Document
	include ActionView::Helpers::NumberHelper

	def initialize(invoice,tenant,logo_path)
		super(:bottom_margin => 75)
		@invoice = invoice
      	image "#{Rails.root}/public/tenant_logo/#{logo_path}", height: 105
		if @invoice.is_proforma?
			title = "Proforma Invoice"
		else
			title = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice Title').id).config_value
		end
		# draw_text "#{title.upcase}", :at => [420,680], style: :bold, size: 12
		move_up 100
		text "#{title.upcase}", :align => :right, :size => 16, :style => :bold

		bounding_box([360,670], width: 180, height: 110, :pad => 2) do 
			move_down 15
			indent(0, 0) do # left and right padding
			  text "#{tenant.company_name}", align: :right, size: 10, style: :bold
			end
			# move_down 5
			indent 0,0 do
			  text "#{tenant.address_1}", align: :right, size: 9
			  unless tenant.address_2.nil?
			    text "#{tenant.address_2}, #{tenant.location}", align: :right, size: 9
			  else
			    text "#{tenant.location}", align: :right, size: 9
			  end
			  text "#{tenant.city}, #{tenant.country}", align: :right, size: 9
			  text "T: #{tenant.phone_1}, #{tenant.mobile_1}", align: :right, size: 9
			  text "E: #{tenant.sales_email}", align: :right, size: 9
			end
			move_down 3
			indent(0,0) do # left and right padding
			  text "VAT Number: #{tenant.vat_number}", align: :right, size: 9, style: :bold unless tenant.vat_number.nil? || tenant.vat_number.empty?
			  text "TIN Number: #{tenant.bp_number}", align: :right, size: 9, style: :bold
			end
		end

		stroke_horizontal_rule
		move_down 20

		text "CUSTOMER DETAILS", style: :bold, size: 10
		customer_header

		move_up 75
		invoice_header

		move_down 50
		invoice_items_header
		if @invoice.license
			invoice_license_items
			move_down 5
			invoice_license_items_footer
		else
			invoice_items
			move_down 5
			invoice_items_footer
		end

		move_up 10
		unless @invoice.bank_id.nil?
			# stroke_rectangle [0,200], 350,80
			bounding_box([0,180], width: 350, height: 80, :pad => 2) do 
			  fill_color "056CA1"
			  text "Transfer funds in account below:", align: :left, size: 9
			  fill_color "222222"
			  move_down 3
			  text "#{@invoice.bank.description.upcase}", style: :bold, size: 11
			  move_down 3
			  indent 0,0 do
			    text "Bank Name: #{@invoice.bank.bank_name}", size: 9
			    text "Account Name: #{@invoice.bank.account_name}", size: 9
			    text "Account Number: #{@invoice.bank.account_number}", size: 9
			    text "Branch: #{@invoice.bank.branch}", size: 9
			    unless @invoice.bank.swift_code.nil? || @invoice.bank.swift_code == ''
			      text "Swift Code: #{@invoice.bank.swift_code}", size: 9
			    end
			  end
			end
		else
			x = 140
			tenant.banks.active.each_with_index do |bank,i|
			# stroke_rectangle [0,200], 90,60
			bounding_box([x*i,200], width: 130, height: 60, :pad => 2) do 
			  fill_color "056CA1"
			    fill_color "222222"
			    move_down 3
			    text "#{bank.description.upcase}", style: :bold, size: 8
			    move_down 3
			    indent 0,0 do
			      text "#{bank.bank_name}", size: 7
			      text "#{bank.account_name}", size: 7
			      text "#{bank.account_number}", size: 7
			      text "#{bank.branch}", size: 7
			      unless bank.swift_code.nil? || bank.swift_code == ''
			        text "Swift Code: #{bank.swift_code}", size: 7
			      end
			    end 
			  end  
			end 
		end

      	number_pages "#{title} ##{@invoice.invoice_number} | Generated from Aibes Billing System ver7.1", :start_count_at => 0, :page_filter => :all, :at => [bounds.right - 300, 8], :align => :right, :size => 7      
      	number_pages "A product of Dapsoft Solutions | <page> of <total>", :start_count_at => 0, :page_filter => :all, :at => [bounds.right - 200, 0], :align => :right, :size => 5.5 
	end

	def customer_header
		table customer_details do
		  	style(columns([1]), :align => :left)
		  	style(row(0..-1), :padding => 1)
			columns(0).width = 100
			columns(1).width = 200
			style(row(0..-1), :borders => [], :size => 9)
			self.position = :left
		end		
	end

	def customer_details
		[
          ["Customer Name:","#{@invoice.client.name.upcase}"],
          ["Customer Address:","#{@invoice.client.client_address}"],
          ["Customer VAT No:","#{@invoice.client.vat_number}"],
          ["Customer TIN No:","#{@invoice.client.bp_number}"],
          ["Customer Email:","#{@invoice.client.email}"],
          ["Customer Telephone:","#{@invoice.client.default_phone}"]
        ]
	end

	def invoice_header
		table invoice_details do
		  	style(columns([1]), :align => :right)
			columns(0).width = 70
			columns(1).width = 70
			style(row(0..-1), :borders => [], :padding => 1, :size => 9)
			self.position = :right
		end
	end

	def invoice_details
		[
			["Document No:","#{@invoice.invoice_number}"],
			["Invoice Date:","#{@invoice.invoice_date.strftime("%d/%m/%Y")}"],
			["Order No:","#{@invoice.order_number}"],
			["Currency:","#{@invoice.currency.name}"]
		]
	end

	def invoice_items_header
		table invoice_table_header do
			style(row(0..-1), :borders => [:left,:right,:top,:bottom], :font_style => :bold, :border_color => "DADCE0", :size => 9)

		  	style(columns([2]), :align => :center)
		  	style(columns([3,4,5,6]), :align => :right)
			style(columns([0]), :width => 53)
			style(columns([2]), :width => 40)
			style(columns([3,4,5,6]), :width => 65)
			self.width = 540
			self.header = true
			self.position = :center
		end
	end

	def invoice_items
		table invoice_items_rows do
			style(row(0..-1), :borders => [:left,:right,:top,:bottom], :border_color => "DADCE0", :size => 9, :padding => 5)
		  	style(columns([2]), :align => :center)
		  	style(columns([3,4,5,6]), :align => :right)
			style(columns([0]), :width => 53)
			style(columns([2]), :width => 40)
			style(columns([3,4,5,6]), :width => 65)
			self.width = 540
			# self.row_colors = ["DADCE0","FFFFFF"]
			self.position = :center
		end
	end

	def invoice_items_footer
		table invoice_table_footer do	
			style(row(0..-1), :borders => [], :size => 9, :font_style => :bold, :padding => 2)
		  	style(columns([0,1]), :align => :right)
			style(columns([1]), :width => 68)
			self.width = 540
			self.header = true
			self.position = :center
		end
	end

	def invoice_license_items_footer
		table invoice_license_table_footer do	
			style(row(0..-1), :borders => [], :size => 9, :font_style => :bold, :padding => 2)
		  	style(columns([0,1]), :align => :right)
			style(columns([1]), :width => 68)
			self.width = 540
			self.header = true
			self.position = :center
		end
	end

	def invoice_license_items
		table invoice_license_items_rows do
			style(row(0..-1), :borders => [:left,:right,:top,:bottom], :border_color => "DADCE0", :size => 9, :padding => 5)
		  	style(columns([2]), :align => :center)
		  	style(columns([3,4,5,6]), :align => :right)
			style(columns([0,2]), :width => 40)
			style(columns([3,4,5,6]), :width => 68)
			self.width = 540
			# self.row_colors = ["DADCE0","FFFFFF"]
			self.position = :center
		end
	end

	def invoice_table_header
		[["HS Code","Description","Qty","Unit Price","Total (Excl)","VAT Amount","Total (Incl)"]]
	end

	def invoice_items_rows
		i = 0
		@invoice.invoice_items.active.map do |item|
			[item.item_code,item.description,item.quantity,number_to_currency(item.net_price, unit: ""),number_to_currency(item.net_total, unit: ""),number_to_currency(item.line_vat, unit: ""),number_to_currency(item.line_total, unit: "")]
		end
	end

	def invoice_license_items_rows
		i = 0
		License.where(invoice_id: @invoice.id, active: true).map do |item|
			[i+=1,"#{item.license_category.name} for the Period #{item.renewal_date.strftime("%d %B %Y")} To #{item.expiry_date.strftime("%d %B %Y")}",item.quantity,number_to_currency(item.unit_price, unit: ""),number_to_currency(item.sub_total, unit: ""),number_to_currency(item.line_vat, unit: ""),number_to_currency(item.amount, unit: "")]
		end
	end

	def invoice_table_footer
        [["Sub Total (Excl)",number_to_currency(@invoice.sub_total, unit: "")]] +
        [["VAT Total",number_to_currency(@invoice.vat, unit: "")]] +
        [["Invoice Total #{@invoice.currency.name}",number_to_currency(@invoice.total, unit: "")]]
	end

	def invoice_license_table_footer
        [["Sub Total (Excl)",number_to_currency(@invoice.license.sub_total, unit: "")]] +
        [["VAT Total",number_to_currency(@invoice.license.vat, unit: "")]] +
        [["Invoice Total #{@invoice.currency.name}",number_to_currency(@invoice.license.amount, unit: "")]]
	end

end