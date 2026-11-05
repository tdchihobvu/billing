class DeliveryNotePdf < Prawn::Document
	include ActionView::Helpers::NumberHelper

	def initialize(invoice,tenant,logo_path)
		super(:bottom_margin => 75)
		@invoice = invoice
      	image "#{Rails.root}/public/tenant_logo/#{logo_path}", height: 105
		title = "Delivery Note"
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

		text "SHIPPING ADDRESS", style: :bold, size: 10
		customer_header

		move_up 75
		invoice_header

		move_down 50
		invoice_items_header
		if @invoice.license
			invoice_license_items
			move_down 5
		else
			invoice_items
			move_down 5
		end

		bounding_box([0,170], width: 540, height: 110, :pad => 2) do 
			move_down 3
			indent(0,0) do # left and right padding
			  text "Received By:  ..................................................................................                Signature:    .....................................................................", align: :left, size: 9, style: :bold unless tenant.vat_number.nil? || tenant.vat_number.empty?
			  text ".", align: :left, size: 10
			  text ".", align: :left, size: 10
			  text ".", align: :left, size: 10
			  text "Delivered By:  ..................................................................................                Signature:    .....................................................................", align: :left, size: 9, style: :bold unless tenant.vat_number.nil? || tenant.vat_number.empty?

			end
		end

      	number_pages "#{title} ##{@invoice.invoice_number} | Generated from Aibes Billing System ver7.1", :start_count_at => 0, :page_filter => :all, :at => [bounds.right - 300, 8], :align => :right, :size => 7      
      	number_pages "A product of Dapsoft Solutions | <page> of <total>", :start_count_at => 0, :page_filter => :all, :at => [bounds.right - 200, 0], :align => :right, :size => 5.5 
	end

	def customer_header
		table customer_details do
		  	style(columns([1]), :align => :left)
		  	style(row(0..-1), :padding => 1)
			columns(0).width = 300
			style(row(0..-1), :borders => [], :size => 9)
			self.position = :left
		end		
	end

	def customer_details
		[
          ["#{@invoice.client.name.upcase}"],
          ["#{@invoice.client.address_1}"],
          ["#{@invoice.client.address_2}"],
          ["#{@invoice.client.location}"],
          ["#{@invoice.client.city}"],
          ["Tel: #{@invoice.client.default_phone}"]
        ]
	end

	def invoice_header
		table invoice_details do
		  	style(columns([1]), :align => :right)
			columns(0).width = 90
			columns(1).width = 90
			style(row(0..-1), :borders => [], :padding => 1, :size => 9)
			self.position = :right
		end
	end

	def invoice_details
		[
			["Delivery Note Ref:","#{@invoice.invoice_number}"],
			["Delivery Date:","#{@invoice.invoice_date.strftime("%d/%m/%Y")}"],
			["Invoice Number:","#{@invoice.invoice_number}"],
			["Order Number:",""]
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

	def invoice_table_header
		[["Qty","Description"]]
	end

	def invoice_items_rows
		i = 0
		@invoice.invoice_items.active.map do |item|
			[item.quantity,item.description]
		end
	end

end