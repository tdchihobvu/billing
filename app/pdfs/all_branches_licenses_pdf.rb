require 'prawn/qrcode'
class AllBranchesLicensesPdf < Prawn::Document
	include ActionView::Helpers::NumberHelper

	def initialize(license,client,current_user,logo_path)
		super(:margin => [0,0,0,0], :page_size => "A4", :page_layout => :portrait)


		@license = license
	    branches = client.branches
	    unless @license.invoice.branches.empty?
	      branches = @license.invoice.branches
	    end
		branches.each do |branch|

			stroke do
			  stroke_color 'A23538'
			  line_width 10
			  # just lower the current y position
			  move_down 50
			  # horizontal_rule
			  vertical_line 0, 838, at: 3
			  vertical_line 0, 838, at: 591
			  horizontal_line 0, 600, at: 2
			  horizontal_line 0, 600, at: 838
			end

			stroke do
			  stroke_color 'FED001'
			  line_width 5
			  # just lower the current y position
			  move_down 50
			  # horizontal_rule
			  vertical_line 7, 833, at: 9
			  vertical_line 7, 833, at: 584
			  horizontal_line 7, 585, at: 9
			  horizontal_line 7, 585, at: 831
			end

			@branch = branch
			qrcode_content = "http://github.com/jabbrwcky/prawn-qrcode"
			# qrcode = RQRCode::QRCode.new(qrcode_content, level: :h, size: 20)
	    	qrcode = RQRCode::QRCode.new("#{@license.license_category.name} for #{@branch.name} Issued On: #{@license.renewal_date.strftime("%d %b %Y")} Valid Until: #{@license.expiry_date.strftime("%d %b %Y")}", level: :h, size: 15, :pos => [150, cursor], stroke: false)

			image "#{Rails.root}/public/tenant_logo/#{logo_path}", fit: [150, 150], position: :center
			move_down 40
			font('Helvetica') do
				text "MUSIC COPYRIGHT LICENSE", align: :center, leading: 3, style: :bold, size: 32
			end
			move_down 30
			text "This license is hereby granted to", align: :center, leading: 3, style: :normal, size: 12
			move_down 35
			text @branch.branch_name.upcase, align: :center, leading: 5, style: :bold, size: 22
			# text @branch.name, align: :center, leading: 5, style: :bold, size: 18

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
			text_box "#{@branch.address_1}, #{@branch.location}, #{@branch.city}", :size => 11, :at => [187,258]
			text_box "#{nature_of_business}", :size => 11, :at => [187,235]
			text_box "#{@license.renewal_date.strftime("%d %B %Y")} To #{@license.expiry_date.strftime("%d %B %Y")}", :size => 11, :at => [187,213]

			text_box "--------------------------------------------------------------------------------------------------------------", :size => 5, :at => [60,112]
			text_box "------------------------------------------------------------------------------------------------------------", :size => 5, :at => [360,112]

			move_down 58
			proprietor = ""
			unless @license.client.cp_name.nil?
				proprietor = @license.client.cp_name
			end
			invoice_details = [
				["#{proprietor}","","#{Date.today.strftime("%d/%m/%Y")}"]
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

	        start_new_page
	    end

        create_stamp("stamp") do
            # fill_color "cc0000"
            text_rendering_mode(:fill_stroke) do
                transparent(0.07){
                # text_box "ZIMURA MUSIC COPYRIGHT LICENSE",
                image "#{Rails.root}/public/tenant_logo/license_background.png", fit: [640, 680], position: :center,
                :size   => 30,
                :width  => bounds.width,
                :height => bounds.height,
                :align  => :center,
                :valign => :center,
                :at     => [20, bounds.height],
                :rotate => 45,
                :rotate_around => :center
            }
            end
          end

        repeat (:all) do
            stamp("stamp")
        end
	end


end