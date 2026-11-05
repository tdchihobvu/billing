require 'prawn/qrcode'
class LicensePlainPdf < Prawn::Document
	include ActionView::Helpers::NumberHelper

	def initialize(license,current_user,logo_path)
		super(:margin => [0,0,0,0], :page_size => "A4", :page_layout => :portrait)


		@license = license
		qrcode_content = "http://github.com/jabbrwcky/prawn-qrcode"
		# qrcode = RQRCode::QRCode.new(qrcode_content, level: :h, size: 20)
    	qrcode = RQRCode::QRCode.new("#{@license.license_category.name} for #{@license.invoice.client.name} Issued On: #{@license.renewal_date.strftime("%d %b %Y")} Valid Until: #{@license.expiry_date.strftime("%d %b %Y")}", level: :h, size: 15, :pos => [150, cursor], stroke: false)
    	# move_down 100
		# image "#{Rails.root}/public/tenant_logo/#{logo_path}", fit: [150, 150], position: :center
		move_down 290
		font('Helvetica') do
			text "MUSIC COPYRIGHT LICENSE", align: :center, leading: 3, style: :bold, size: 32
		end
		move_down 30
		text "This license is hereby granted to", align: :center, leading: 3, style: :normal, size: 12
		move_down 35
		text @license.invoice.client.name.upcase, align: :center, leading: 5, style: :bold, size: 22

		# mask(:line_width) do
		# line_width 1
		# stroke_horizontal_rule
		# end

		# text "is in full compliance with the copyright & neighbouring rights act chapter 26:05 as amended", align: :center, leading: 3
		move_down 20
		font('Helvetica') do
			text "to publicly perfom copyright music", style: :italic, size: 12, align: :center, leading: 4
			text "under ZIMURA's repertoire in compliance with the", style: :italic, size: 12, align: :center, leading: 4
			text "Copyright and Neighbouring Rights Act [Chapter 26:05]", style: :italic, size: 12, align: :center, leading: 4
		end

		nature_of_business = 'Not Defined'
		unless @license.invoice.client.industry.nil?
			nature_of_business = "#{@license.invoice.client.industry.name.upcase}"
		end

		move_down 40
		client_details = [
			["Licensed For",".................................................................................................................."],
			["Address",".................................................................................................................."],
			["Nature of Business",".................................................................................................................."],
			["Valid From",".................................................................................................................."],
		]
		table(client_details, :column_widths => [120,360], :cell_style => { :borders => [], :padding => 5, :size => 11, :font_style => :bold }, :position => :center)

		text_box "#{@license.license_for}", :size => 11, :at => [187,282]
		text_box "#{@license.invoice.client.address_1}, #{@license.invoice.client.location}, #{@license.invoice.client.city}", :size => 11, :at => [187,258]
		# self.split(' ').map {|w| w.capitalize }.join(' ') this method is used to capitalize each letter in a string
		text_box "#{nature_of_business.titleize}", :size => 11, :at => [187,235]
		text_box "#{@license.renewal_date.strftime("%d %B %Y")} To #{@license.expiry_date.strftime("%d %B %Y")}", :size => 11, :at => [187,213]

		text_box "--------------------------------------------------------------------------------------------------------------", :size => 5, :at => [60,112]
		text_box "------------------------------------------------------------------------------------------------------------", :size => 5, :at => [360,112]

		move_down 58
		proprietor = "The Manager"
		unless @license.client.cp_name.nil?
			proprietor = @license.client.cp_name.titleize
		end
		invoice_details = [
			["#{proprietor.titleize}","","#{Date.today.strftime("%d/%m/%Y")}"]
		]
		table(invoice_details, :column_widths => [180,190,100], :cell_style => { :borders => [], :padding => 3, :size => 12, :font_style => :bold }, :position => :center)
		move_down 10
		invoice_details = [
			["Name of Proprietor","","Date of Issue"]
		]
		table(invoice_details, :column_widths => [180,190,100], :cell_style => { :borders => [], :padding => 3, :size => 12 }, :position => :center)
		move_down 20

		line_width 0
		bounding_box([260,160], width: 330, height: 110, :pad => 2) do
			render_qr_code(qrcode)
		end

	end


end