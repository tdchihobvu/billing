class QuotationsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_quotation, only: %i[ show edit update destroy print send ]

  # GET /quotations
  def index
    @quotations = tenant.quotations.order(quotation_date: :desc).includes(:client, :currency).limit(30)
  end

  # GET /quotations/1
  def show
    @tenant = tenant
  end

  # GET /quotations/new
  def new
    @quotation = Quotation.new
    @quotation.quotation_date = Date.today
    unless tenant.system_settings.empty?
      quote_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Quote No.').id).config_value
      last = tenant.quotations[-1]
      if last.nil?
        @quotation.quotation_number = quote_format
      else
        @quotation.quotation_number = last.quotation_number.next
      end
    end
    10.times {@quotation.quotation_items.build}
  end

  # GET /quotations/1/edit
  def edit
    3.times {@quotation.quotation_items.build}
  end

  # POST /quotations
  def create
    @quotation = Quotation.new(quotation_params)
    @quotation.user_id = current_user.id
    if @quotation.save
      redirect_to @quotation, notice: "Quotation was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /quotations/1
  def update
    if @quotation.update(quotation_params)
      redirect_to @quotation, notice: "Quotation was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /quotations/1
  def destroy
    @quotation.destroy!
    redirect_to quotations_url, notice: "Quotation was successfully destroyed.", status: :see_other
  end

  def print 
    pdf = Prawn::Document.new 
    case template
    when 'aibes'
    # Start of PDF
      pdf.image "#{Rails.root}/app/assets/images/dapsoft_logo.png", height: 100

      pdf.fill_color "2880AE"
      pdf.draw_text "QUOTATION", :at => [398,690], style: :bold, size: 25
      pdf.fill_color "222222"
      pdf.bounding_box([400,680], width: 330, height: 110, :pad => 2) do 
        pdf.move_down 8
        pdf.indent(0, 15) do # left and right padding
          pdf.text "#{tenant.company_name}", size: 10, style: :bold
        end
        pdf.move_down 3
        pdf.indent 0,0 do
          pdf.text "#{tenant.address_1}", align: :left, size: 9
          unless tenant.address_2.nil?
            pdf.text "#{tenant.address_2}", align: :left, size: 9
          end
          pdf.text "#{tenant.location}", align: :left, size: 9
          pdf.text "#{tenant.city}, #{tenant.country}", align: :left, size: 9
          pdf.text "T: #{tenant.phone_1}, #{tenant.mobile_1}", align: :left, size: 9
          pdf.text "E: #{tenant.sales_email}", align: :left, size: 9
        end
        pdf.move_down 3
        pdf.indent(0,0) do # left and right padding
          pdf.text "VAT: #{tenant.vat_number} | TIN: #{tenant.bp_number}", size: 9, style: :bold
        end
      end

      pdf.stroke_horizontal_rule
      pdf.move_down 15

      invoice_details = [
        ["Quote No:","#{@quotation.quotation_number}"],
        ["Quote Date:","#{@quotation.quotation_date.strftime("%d/%m/%Y")}"],
        ["Order No:","#{@quotation.order_number}"],
        ["Valid For:", "#{@quotation.validity} days"],
        ["Sales Rep:","#{current_user.firstname}"]
      ]
      pdf.table(invoice_details, :column_widths => [70, 70], :cell_style => { :borders => [], :padding => 0, :size => 9 }, :position => :right)

      # pdf.stroke_rectangle [0,500], 330,90
      pdf.bounding_box([0,560], width: 200, height: 80, :pad => 2) do 
        pdf.move_down 8
        pdf.text "Quote To:", style: :bold, size: 9
        pdf.move_down 2
        pdf.text "#{@quotation.client.name.upcase}", align: :left, size: 9, style: :bold
        # pdf.stroke_horizontal_rule
        pdf.indent 0,0 do
          pdf.text "#{@quotation.client.address_1}", align: :left, size: 9
          unless @quotation.client.address_2.nil?
            pdf.text "#{@quotation.client.address_2}", align: :left, size: 9
          end
          pdf.text "#{@quotation.client.location}", align: :left, size: 9
          pdf.text "#{@quotation.client.city}, #{@quotation.client.country}", align: :left, size: 9
        end
      end

      unless @quotation.quotation_items.empty?
        quote_items = Array.new(){Array.new()}
        quote_header = [
        ["Item","Description","Qty","Unit Price","Line Vat","Total (Incl)"]
        ]
        @quotation.quotation_items.each_with_index do |item,i|
          quote_items.push [i+=1,item.description,item.quantity,sprintf("%0.03f", item.net_price),sprintf("%0.02f", item.line_vat),number_to_currency(item.line_total, unit: "")]
        end

        pdf.table(quote_header, :column_widths => [30,220,50,80,80,80], :cell_style => { :borders => [:top,:left,:right,:bottom], :padding => 3, :size => 9, :align => :left }, :position => :left)
        pdf.table(quote_items, :column_widths => [30,220,50,80,80,80], :cell_style => { :borders => [:left,:right,:bottom], :padding => 3, :size => 9, :align => :left }, :position => :left)

      end
      pdf.move_down 10

      quote_footer = [
      ["Sub Total",number_to_currency(@quotation.sub_total, unit: "#{@quotation.currency.symbol} ")],
      ["VAT",number_to_currency(@quotation.vat, unit: "#{@quotation.currency.symbol} ")],
      ["Total",number_to_currency(@quotation.total, unit: "#{@quotation.currency.symbol} ")],
      ]

      pdf.table(quote_footer, :column_widths => [60,100], :cell_style => { :borders => [:bottom], :padding => 3, :size => 9.5, :align => :left }, :position => :right)


      # pdf.stroke_rectangle [0,200], 350,80
      pdf.bounding_box([0,180], width: 350, height: 80, :pad => 2) do 
        pdf.text "#{@quotation.bank.description.upcase}", style: :bold, size: 11
        pdf.move_down 3
        pdf.indent 0,0 do
          unless @quotation.bank_id.nil?
            pdf.text "Bank Name: #{@quotation.bank.bank_name}", size: 9
            pdf.text "Account Name: #{@quotation.bank.account_name}", size: 9
            pdf.text "Account Number: #{@quotation.bank.account_number}", size: 9
            pdf.text "Branch: #{@quotation.bank.branch}", size: 9
            unless @quotation.bank.swift_code.nil? || @quotation.bank.swift_code == ''
              pdf.text "Swift Code: #{@quotation.bank.swift_code}", size: 9
            end
          end
        end
      end

      # pdf.stroke_rectangle [0,200], 350,80
      pdf.bounding_box([200,180], width: 350, height: 80, :pad => 2) do 
        pdf.text "Terms & Conditions", style: :bold, size: 11
        pdf.move_down 3
        pdf.indent 0,0 do
          # pdf.text "#{ActionView::Base.full_sanitizer.sanitize(@quotation.quotation_terms) }", style: :normal, size: 10
          pdf.styled_text "<ol style='font-size: 9px'>#{@quotation.quotation_terms}</ol>"
        end
      end

      pdf.bounding_box([0,20], width: 500, height: 35, :pad => 2) do
        pdf.image "#{Rails.root}/app/assets/images/partners.png", height: 30, align: :center
      end

      pdf.number_pages "Generated from Aibes Billing System ver7.1", :start_count_at => 0, :page_filter => :all, :at => [pdf.bounds.right - 200, 8], :align => :right, :size => 7      
      pdf.number_pages "A product of Dapsoft Solutions | <page> of <total>", :start_count_at => 0, :page_filter => :all, :at => [pdf.bounds.right - 200, 0], :align => :right, :size => 5.5   
      # End of PDF
    else
      # Start of PDF
        pdf.text "#{tenant.company_name}", style: :bold, size: 16
        pdf.text "#{tenant.address_1}", style: :normal, size: 11
        pdf.text "#{tenant.address_2}", style: :normal, size: 11
        pdf.text "#{tenant.location}, #{tenant.city}", style: :normal, size: 11
        pdf.text "#{tenant.country}", style: :normal, size: 11
        pdf.move_up 70
        pdf.text "Quotation", style: :bold, size: 18, align: :right
        pdf.text "Quote No:    #{@quotation.quotation_number}", style: :normal, size: 10, align: :right
        pdf.text "Quote Date: #{@quotation.quotation_date.strftime("%d/%m/%Y")}", style: :normal, size: 10, align: :right
        pdf.text "Sales Rep:        #{current_user.firstname}", style: :normal, size: 10, align: :right
        pdf.text "#{current_user.email}", style: :normal, size: 10, align: :right
        pdf.move_down 20
        pdf.text "Bill To:", style: :bold, size: 11
        pdf.text "#{@quotation.client.name}", style: :normal, size: 10
        pdf.text "#{@quotation.client.address_1}", style: :normal, size: 10
        pdf.text "#{@quotation.client.address_2}", style: :normal, size: 10
        pdf.text "#{@quotation.client.location}, #{@quotation.client.city}", style: :normal, size: 10
        pdf.text "#{@quotation.client.country}", style: :normal, size: 10

        pdf.move_down 20
        unless @quotation.quotation_items.empty?
          data = Array.new(){Array.new()}
          data.push ["#","Description","Price","Qty","Vat","Line Total"]
          @quotation.quotation_items.each_with_index do |item,i|
            data.push [i+=1,item.description,item.unit_price,item.quantity,item.line_vat,item.line_total]
          end
          pdf.table data,:column_widths => {0=>30,1=>200,2=>90,3=>40,4=>90,5=>90},:position => :center,:row_colors => ["FFFFFF","FFFFFF"]

          data = Array.new(){Array.new()}
          data.push ["Sub Total","#{@quotation.sub_total}"]
          data.push ["Vat Total","#{@quotation.vat}"]
          data.push ["Total","#{@quotation.total}"]
          pdf.table data,:column_widths => {0=>450,1=>90},:position => :center,:row_colors => ["FFFFFF","FFFFFF"]
        else
          pdf.text "No items to display.", align: :center, size: 11
        end
        pdf.move_down 20
        pdf.text "Terms & Conditions", style: :bold, size: 11
        pdf.move_down 5
        pdf.text "#{ActionView::Base.full_sanitizer.sanitize(@quotation.quotation_terms) }", style: :normal, size: 10
      # End of PDF
    end
    send_data(pdf.render, 
      filename: "#{@quotation.client.name} - Quotation #{@quotation.quotation_number}.pdf",
      type: 'application/pdf', disposition: 'inline')   
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_quotation
      @quotation = Quotation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def quotation_params
      params.require(:quotation).permit(:client_id, :quotation_date, :quotation_number, :order_number, :validity, :quotation_terms, :currency_id, :bank_id, :deleted, :product_pricing, quotation_items_attributes: [:id, :description, :quantity, :unit_price, :vat_type_id])
    end
end
