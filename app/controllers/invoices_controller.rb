class InvoicesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_invoice, only: %i[ show edit update fiscalise save_fiscal_invoice destroy print receipt delivery_note disable edit_license sms_reminder email_reminder assign_branches setoff]

  # GET /invoices
  def index
    @invoices = tenant.invoices.active.includes(:client, :currency, :invoice_items).order('invoice_date Desc').where("invoice_date BETWEEN '#{statement_start_date}' AND '#{Date.today}'")
    # tenant.invoices.where('due_date IS NULL').each do |i|
    #   puts("dealing with #{i.invoice_number}")
    #   i.update_attribute(:due_date, (i.invoice_date + invoice_validity.days))
    # end
  end

  def inactive
    @invoices = tenant.invoices.inactive.order('invoice_date Desc').where("invoice_date BETWEEN '#{statement_start_date}' AND '#{Date.today}'")
  end

  # GET /invoices/1
  def show
    @tenant = tenant
    @statement_start_date = statement_start_date
  end

  def void_invoice
    @invoice = Invoice.find(params[:id])
    void_reason = "#{params[:void_reason]}"
    notification = Notification.find(params[:notification_id])
    if @invoice.update(deleted: true, void_date: Date.today, void_reason: void_reason, status: 'Void')
      unless notification.nil?
        notification.update(processed: true, processed_by: current_user.id, read: true)
      end
      redirect_to @invoice, notice: "Invoice was successfully voided."
    end
  end

  # GET /invoices/new
  def new
    @invoice = Invoice.new
    if params[:quotation].present?
      @quotation = Quotation.find(params[:quotation])
      @invoice.invoice_date = Date.today
      unless tenant.system_settings.empty?
        inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice No.').id).config_value
        last = tenant.invoices.order('invoice_number asc').all_sales[-1]
        if last.nil?
          @invoice.invoice_number = inv_format
        else
          @invoice.invoice_number = last.invoice_number.next
        end
      end
      @invoice.currency_id = @quotation.currency_id
      @invoice.client_id = @quotation.client_id
      @invoice.product_pricing = @quotation.product_pricing
      @quotation.quotation_items.where('unit_price > 0').each do |item|
        @invoice.invoice_items.build(description: item.description, quantity: item.quantity, unit_price: item.unit_price, vat_type_id: item.vat_type_id)
      end
    end
  end

  def duplicate
    @quotation = Invoice.find(params[:id])
    @invoice = Invoice.new
    @invoice.invoice_date = Date.today
    @invoice.is_proforma = true
    unless tenant.system_settings.empty?
      inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Proforma Invoice No.').id).config_value
      last = tenant.invoices.order('invoice_number asc').all_proformas[-1]
      # puts("last is #{last.invoice_number}")
      if last.nil?
        @invoice.invoice_number = inv_format
      else
        @invoice.invoice_number = last.invoice_number.next
      end
    end
    @invoice.description = @quotation.description
    @invoice.currency_id = @quotation.currency_id
    @invoice.client_id = @quotation.client_id
    @invoice.product_pricing = @quotation.product_pricing
    @quotation.invoice_items.where('unit_price > 0').each do |item|
      @invoice.invoice_items.build(description: item.description, quantity: item.quantity, unit_price: item.unit_price, vat_type_id: item.vat_type_id)
    end      
  end

  # GET /invoices/1/edit
  def edit
    if @invoice.is_license
      redirect_to edit_license_invoices_url(id: @invoice)
    else
      2.times {@invoice.invoice_items.build}
    end
  end

  def assign_branches

  end

  # POST /invoices
  # def create
  #   @invoice = Invoice.new(invoice_params)
  #   @invoice.user_id = current_user.id
  #   @invoice.tenant_id = tenant.id
  #   category = params[:invoice][:invoice_category_id]
  #   @invoice.build_license
  #   if @invoice.save
  #     redirect_to @invoice, notice: "Invoice was successfully created."
  #   else
  #     if category = 2
  #       @invoice.build_license
  #       render :license, status: :unprocessable_entity
  #     else
  #       render :new, status: :unprocessable_entity
  #     end
  #   end
  # end

  def create
    @invoice = Invoice.new(invoice_params)
    @invoice.user_id = current_user.id
    @invoice.tenant_id = tenant.id
    category = params[:invoice][:invoice_category_id]
    if @invoice.save
      @invoice.update_attribute(:invoice_total, @invoice.total)
      @invoice.update_attribute(:due_date, (@invoice.invoice_date + invoice_validity.days))
      redirect_to @invoice, notice: "Invoice was successfully created."
    else
      if category = 2
        @invoice.build_license
        render :license, status: :unprocessable_entity
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /invoices/1
  def update
    if @invoice.update(invoice_params)
      @invoice.update_attribute(:due_date, (@invoice.invoice_date + invoice_validity.days))
      redirect_to @invoice, notice: "Invoice was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def fiscalise
    @invoice.invoice_date = Date.today
    unless tenant.system_settings.empty?
      inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice No.').id).config_value
      last = tenant.invoices.order('invoice_number asc').all_sales[-1]
        # puts("************ last is #{last.invoice_number}")
      if last.nil?
        @invoice.invoice_number = inv_format
      else
        @invoice.invoice_number = last.invoice_number.next
      end
    end
    if @invoice.is_license
      redirect_to edit_license_invoices_url(id: @invoice)
    else
      2.times {@invoice.invoice_items.build}
    end
  end

  def save_fiscal_invoice
    if @invoice.update(invoice_params)
      # get the last fiscal invoice 
      last_invoice = tenant.invoices.active.where(is_proforma: false).last
      # puts("************** #{last_invoice.invoice_number}")
      unless last_invoice.nil?
        @invoice.update_attribute(:invoice_number, last_invoice.invoice_number.next)
      else
        inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice No.').id).config_value
        @invoice.update_attribute(:invoice_number, inv_format)
      end
      @invoice.update_attribute(:is_proforma, false)
      redirect_to @invoice, notice: "Invoice was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /invoices/1
  def destroy
    @invoice.update_attribute(:deleted, true)
    redirect_to invoices_url, notice: "Invoice was successfully destroyed.", status: :see_other
  end

  def disable
    if @invoice.update_attribute(:deleted, true)
      redirect_to invoices_url, notice: "Invoice was successfully removed.", status: :see_other
    end
  end

  def proforma
    @invoice = Invoice.new
    @invoice.invoice_date = Date.today
    @invoice.is_proforma = true
    unless tenant.system_settings.empty?
      inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Proforma Invoice No.').id).config_value
      last = tenant.invoices.order('invoice_number asc').all_proformas[-1]
      # puts("last is #{last.invoice_number}")
      if last.nil?
        @invoice.invoice_number = inv_format
      else
        @invoice.invoice_number = last.invoice_number.next
      end
    end
    10.times {@invoice.invoice_items.build}    
  end

  # def license
  #   @invoice = Invoice.new
  #   @invoice.invoice_date = Date.today
  #   # @invoice.is_proforma = true
  #   @invoice.invoice_category_id = 2
  #   @invoice.product_pricing = 'none'
  #   license_category = LicenseCategory.first
  #   unless license_category.nil?
  #     @invoice.description = license_category.name
  #   end
  #   unless tenant.system_settings.empty?
  #     inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice No.').id).config_value
  #     last = tenant.invoices.all_sales[-1]
  #     if last.nil?
  #       @invoice.invoice_number = inv_format
  #     else
  #       @invoice.invoice_number = last.invoice_number.next
  #     end
  #   end
  #   @invoice.build_license   
  # end

  def license
    @invoice = Invoice.new(
      invoice_date: Date.current,
      invoice_category_id: 2,
      product_pricing: 'none',
      description: 'Music Copyright License',
      invoice_number: next_invoice_number
    )

    @invoice.build_license
  end

  def credit_note
    @tenant = tenant
    @credit_note = CreditNote.new
    last = CreditNote.last
    unless last.nil?
      @credit_note.document_number = last.document_number.next
    else
      @credit_note.document_number = "CRN00001"
    end
    @credit_note.transaction_date = Date.today
    @credit_note.tenant_id = tenant.id
  end

  def save_credit_note
    @credit_note = CreditNote.new(credit_note_params)
    @credit_note.user_id = current_user.id
    if @credit_note.save
      redirect_to credit_notes_invoices_url(id: @credit_note), notice: "Credit Note was successfully created."
    else
      render :credit_note, status: :unprocessable_entity
    end

  end

  def setoff

    if request.post?
      amount = params[:amount].to_d
      transaction_date = params[:transaction_date].to_date
      reason = params[:reason].to_s.strip
      payment_form_id = params[:payment_form_id].to_i

      if amount <= 0
        redirect_to setoff_invoice_path(@invoice),
                    alert: "Setoff amount must be greater than zero."
        return
      end

      if amount > @invoice.invoice_balance.to_d
        redirect_to setoff_invoices_path(id: @invoice),
                    alert: "Setoff amount cannot exceed the outstanding balance."
        return
      end

      if reason.blank?
        redirect_to setoff_invoice_path(@invoice),
                    alert: "A reason is required for a setoff."
        return
      end

      rec_no = Receipt.generate_receipt_number(current_user.tenant)

      receipt = @invoice.receipts.build(
        transaction_date: transaction_date,
        payment_form_id: payment_form_id,
        receipt_type: "Setoff",
        client: @invoice.client,
        currency: @invoice.currency,
        amount: amount,
        actual_paid: amount,
        description: "Setoff: #{reason}",
        reason: reason,
        source_reference: rec_no,
        reference_number: rec_no,
        user: current_user,
        tenant_id: @invoice.tenant_id,
        transaction_source: 'BaseApplication'
      )

      if receipt.save
        @invoice.update_balance

        redirect_to @invoice,
                    notice: "Setoff of #{@invoice.currency.symbol} #{format('%.2f', amount)} posted successfully."
      else
        Rails.logger.error "SETTOFF RECEIPT ERRORS: #{receipt.errors.full_messages}"
        redirect_to setoff_invoice_path(@invoice),
                    alert: receipt.errors.full_messages.to_sentence
      end
    end
  end

  def credit_notes
    @credit_notes = CreditNote.where(tenant_id: tenant.id).order('created_at Desc')
  end

  def print_credit_note
    @credit_note = CreditNote.find(params[:id])
    invoice = @credit_note.invoice
    pdf = Prawn::Document.new 
    case template
    # get the template type
    when 'gt'
      # Start of PDF

      pdf.image "#{Rails.root}/app/assets/images/logo.jpg", height: 52
      pdf.move_down 20

      data = [
        ["#{tenant.address_1}"],
        ["#{tenant.address_2}, #{tenant.location}"],
        ["#{tenant.city}, #{tenant.country}"],
        ["Tel: #{tenant.phone_1}"],
        ["Email: #{tenant.sales_email}"]

      ]
      pdf.table(data, :cell_style => { :borders => [], :padding => 1, :size => 9 }, :position => :left)

      pdf.move_up 30

      title = "Credit Note"

      pdf.draw_text "#{title}:", :at => [426,625], style: :bold, size: 10

      invoice_details = [
        ["Invoice No:","#{@invoice.invoice_number}/#{Date.today.strftime("%y")}"],
        ["Date:","#{@invoice.invoice_date.strftime("%d/%m/%Y")}"],
        ["VAT No:","#{tenant.vat_number}"],
        ["TIN No:","#{tenant.bp_number}"]
      ]
      pdf.table(invoice_details, :column_widths => [55, 60], :cell_style => { :borders => [], :padding => 1, :size => 9 }, :position => :right)

      pdf.draw_text "Invoice Currency #{@invoice.currency.name}:", :at => [426,520], style: :bold, size: 9

      pdf.stroke_rectangle [0,500], 330,90
      pdf.bounding_box([0,500], width: 330, height: 90, :pad => 2) do 
        pdf.move_down 8
        pdf.text 'Client Details', align: :center, size: 9, style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 5
        pdf.indent 3,0 do
          pdf.text "Attention: #{@invoice.client.cp_name}", align: :left, size: 9
          pdf.text "#{@invoice.client.name}", align: :left, size: 9
          pdf.text "#{@invoice.client.address_1}, #{@invoice.client.location}, #{@invoice.client.city}", align: :left, size: 9
          pdf.text "Customer VAT No: #{@invoice.client.vat_number}", align: :left, size: 9
          pdf.text "Customer TIN No: #{@invoice.client.bp_number}", align: :left, size: 9
        end
      end

      pdf.move_down 20
      unless @invoice.invoice_items.empty?
        invoice_items = Array.new(){Array.new()}
        invoice_header = [
        ["Item Code","Description","Qty","Unit Price","Total (Excl VAT)","VAT"]
        ]
        @invoice.invoice_items.each_with_index do |item,i|
          invoice_items.push [i+=1,item.description,item.quantity,number_to_currency(item.unit_price, unit: ""),number_to_currency(item.line_total, unit: ""),"15%"]
        end

        pdf.table(invoice_header, :column_widths => [50,240,40,70,110,30], :cell_style => { :borders => [:top,:left,:right,:bottom], :padding => 3, :size => 9, :align => :center }, :position => :left)
        pdf.table(invoice_items, :column_widths => [50,240,40,70,110,30], :cell_style => { :borders => [:left,:right,:bottom], :padding => 3, :size => 9, :align => :center }, :position => :left)

      end
      pdf.move_down 10
      unless @invoice.invoice_items.empty?
        invoice_footer = [
        ["Sub Total",number_to_currency(@invoice.sub_total, unit: "")],
        ["VAT 15%",number_to_currency(@invoice.vat, unit: "")],
        ["Invoice Total",number_to_currency(@invoice.total, unit: "")],
        ]
        pdf.table(invoice_footer, :column_widths => [80,60], :cell_style => { :borders => [:bottom], :padding => 3, :size => 9.5, :align => :left }, :position => :right)

      end
      pdf.move_up 10
      bank = [
        ["Transfer Funds to:"],
        ["#{@invoice.bank.account_name}"],
        ["Bank - #{@invoice.bank.bank_name}"],
        ["Branch - #{@invoice.bank.branch}"],
        ["Account # #{@invoice.bank.account_number}"],

      ]
      pdf.table(bank, :cell_style => { :borders => [], :padding => 1, :size => 9 }, :position => :center)

      pdf.draw_text "#{title} ##{@invoice.invoice_number} | Generated from Aibes Billing System ver7.1", :at => [0,0], style: :normal, size: 6
    when 'aibes'
      # Start of PDF

      pdf.image "#{Rails.root}/public/tenant_logo/#{logo_path}", height: 100

      title = "Credit Note"

      pdf.draw_text "#{title.upcase}", :at => [400,720], style: :bold, size: 12

      pdf.bounding_box([400,715], width: 330, height: 110, :pad => 2) do 
        pdf.move_down 8
        pdf.indent(0, 15) do # left and right padding
          pdf.text "#{tenant.company_name}", size: 10, style: :bold
        end
        pdf.move_down 5
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
          pdf.text "VAT Number: #{tenant.vat_number}", size: 9, style: :bold
          pdf.text "TIN Number: #{tenant.bp_number}", size: 9, style: :bold
        end
      end

      pdf.stroke_horizontal_rule
      pdf.move_down 32

      invoice_details = [
        ["Document No:","#{@credit_note.document_number}"],
        ["Reference No:","#{@credit_note.reference_number}"],
        ["Order No:","#{invoice.order_number}"],
        ["Currency:","#{invoice.currency.name}"]

      ]
      pdf.table(invoice_details, :column_widths => [70, 70], :cell_style => { :borders => [], :padding => 0, :size => 9 }, :position => :right)

      pdf.move_up 50
      pdf.fill_color "056CA1"
      pdf.text "Customer Details", align: :left, size: 9
      pdf.fill_color "222222"
      invoice_details = [
          ["Customer Name:","#{invoice.client.name.upcase}"],
          ["Customer Address:","#{invoice.client.client_address}"],
          ["Customer VAT No:","#{invoice.client.vat_number}"],
          ["Customer TIN No:","#{invoice.client.bp_number}"],
          ["Customer Email:","#{invoice.client.email}"],
          ["Customer Telephone:","#{invoice.client.default_phone}"]

      ]
      pdf.table(invoice_details, :column_widths => [100, 200], :cell_style => { :borders => [], :padding => 0, :size => 9 }, :position => :left)

      pdf.move_down 15
      pdf.text "Reason: #{@credit_note.reason}", align: :left, size: 9
      
      pdf.move_down 15

      unless invoice.invoice_items.empty?
        invoice_items = Array.new(){Array.new()}
        invoice_header = [
        ["HS Code","Description","Qty","Unit Price","Total (Excl)","VAT Amount","Total (Incl)"]
        ]
        invoice.invoice_items.each_with_index do |item,i|
          invoice_items.push [item.item_code,item.description,item.quantity,number_to_currency(item.net_price, unit: ""),number_to_currency(item.net_total, unit: ""),number_to_currency(item.line_vat, unit: ""),number_to_currency(item.line_total, unit: "")]
        end

        pdf.table(invoice_header, :column_widths => [50,180,30,70,70,70,70], :cell_style => { :borders => [:top,:left,:right,:bottom], :padding => 4, :size => 9, :align => :left }, :position => :left)
        pdf.table(invoice_items, :column_widths => [50,180,30,70,70,70,70], :cell_style => { :borders => [:left,:right,:bottom], :padding => 4, :size => 9, :align => :left }, :position => :left)

      end
      pdf.move_down 10
      unless invoice.invoice_items.empty?
        invoice_footer = [
        ["Sub Total (Excl)",number_to_currency(invoice.sub_total, unit: "")],
        ["VAT Total",number_to_currency(invoice.vat, unit: "")],
        ["Invoice Total #{invoice.currency.name}",number_to_currency(invoice.total, unit: "")],
        ]

        pdf.table(invoice_footer, :column_widths => [80,70], :cell_style => { :borders => [:bottom], :padding => 4, :size => 9, :align => :left }, :position => :right)

      end
      pdf.move_up 10
      # bank = [
      #   ["Transfer Funds to:"],
      #   ["#{@invoice.bank.account_name}"],
      #   ["Bank - #{@invoice.bank.bank_name}"],
      #   ["Branch - #{@invoice.bank.branch}"],
      #   ["Account # #{@invoice.bank.account_number}"],

      # ]
      # pdf.table(bank, :cell_style => { :borders => [], :padding => 1, :size => 9 }, :position => :center)

      pdf.number_pages "#{title} for ##{@credit_note.reference_number} | Generated from Aibes Billing System ver7.1", :start_count_at => 0, :page_filter => :all, :at => [pdf.bounds.right - 300, 8], :align => :right, :size => 7      
      pdf.number_pages "A product of Dapsoft Solutions | <page> of <total>", :start_count_at => 0, :page_filter => :all, :at => [pdf.bounds.right - 200, 0], :align => :right, :size => 5.5  
    else
      # Start of PDF
      pdf.text "#{tenant.company_name}", style: :bold, size: 16
      pdf.text "#{tenant.address_1}", style: :normal, size: 11
      pdf.text "#{tenant.address_2}", style: :normal, size: 11
      pdf.text "#{tenant.location}, #{tenant.city}", style: :normal, size: 11
      pdf.text "#{tenant.country}", style: :normal, size: 11
      pdf.move_up 70
      if @invoice.is_proforma?
        pdf.text "Proforma Invoice", style: :bold, size: 18, align: :right
        pdf.text "Proforma Invoice No:    #{@invoice.invoice_number}", style: :normal, size: 10, align: :right
      else
        title = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice Title').id).config_value
        pdf.text "#{title}", style: :bold, size: 18, align: :right
        pdf.text "Invoice No:    #{@invoice.invoice_number}", style: :normal, size: 10, align: :right
      end
      pdf.text "Invoice Date: #{@invoice.invoice_date.strftime("%d/%m/%Y")}", style: :normal, size: 10, align: :right
      pdf.text "Sales Rep:        #{current_user.firstname}", style: :normal, size: 10, align: :right
      pdf.text "#{current_user.email}", style: :normal, size: 10, align: :right
      pdf.move_down 20
      pdf.text "Bill To:", style: :bold, size: 11
      pdf.text "#{@invoice.client.name}", style: :normal, size: 10
      pdf.text "#{@invoice.client.address_1}", style: :normal, size: 10
      pdf.text "#{@invoice.client.address_2}", style: :normal, size: 10
      pdf.text "#{@invoice.client.location}, #{@invoice.client.city}", style: :normal, size: 10
      pdf.text "#{@invoice.client.country}", style: :normal, size: 10

      pdf.move_down 20
      unless @invoice.invoice_items.empty?
        data = Array.new(){Array.new()}
        data.push ["#","Description","Price","Qty","Vat","Line Total"]
        @invoice.invoice_items.each_with_index do |item,i|
          data.push [i+=1,item.description,item.unit_price,item.quantity,item.line_vat,item.line_total]
        end
        pdf.table data,:column_widths => {0=>30,1=>200,2=>90,3=>40,4=>90,5=>90},:position => :center,:row_colors => ["FFFFFF","FFFFFF"]

        data = Array.new(){Array.new()}
        data.push ["Sub Total","#{@invoice.sub_total}"]
        data.push ["Vat Total","#{@invoice.vat}"]
        data.push ["Total","#{@invoice.total}"]
        pdf.table data,:column_widths => {0=>450,1=>90},:position => :center,:row_colors => ["FFFFFF","FFFFFF"]
      else
        pdf.text "No items to display.", align: :center, size: 11
      end
    end
    # End of PDF
    send_data(pdf.render, 
      filename: "Credit Note #{@credit_note.document_number} - #{invoice.invoice_number}.pdf",
      type: 'application/pdf', disposition: 'inline')  
  end

  def sms_reminder

  end

  def email_reminder
    
  end

  def print
    respond_to do |format|
      format.html
      format.pdf do 
        pdf = InvoicePdf.new(@invoice,tenant,logo_path)
        send_data pdf.render, :filename => "#{@invoice.client.name} Invoice #{@invoice.invoice_number}.pdf",
                    :type => "application/pdf", :disposition => "inline"
      end
    end
  end

  def receipt
    respond_to do |format|
      format.text do
        render layout: false
      end
    end
  end

  def delivery_note
    respond_to do |format|
      format.html
      format.pdf do 
        pdf = DeliveryNotePdf.new(@invoice,tenant,logo_path)
        send_data pdf.render, :filename => "#{@invoice.client.name} Delivery Note #{@invoice.invoice_number}.pdf",
                    :type => "application/pdf", :disposition => "inline"
      end
    end
  end

  private
  
    # Use callbacks to share common setup or constraints between actions.
    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    def next_invoice_number
      config_key = ConfigKey.find_by(name: 'Invoice No.')
      setting = tenant.system_settings.find_by(config_key_id: config_key.id)

      return unless setting

      last = tenant.invoices.order(invoice_number: :asc).all_sales.last

      last.nil? ? setting.config_value : last.invoice_number.next
    end


    # Only allow a list of trusted parameters through.
    # def invoice_params
    #   params.require(:invoice).permit(:client_id, :user_id, :invoice_date, :invoice_number,:description, :order_number, :currency_id, :bank_id, :invoice_category_id, :deleted, :is_proforma, :sent, :paid, :product_pricing, :unit_price, :quantity, invoice_items_attributes: [:id, :description, :quantity, :unit_price, :vat_type_id], license_attributes: [:id, :invoice_id, :client_id, :license_category_id, :license_option_id, :renewal_date, :auto_renewal, :amount, :quantity, :special_days])
    # end

    def invoice_params
      params.require(:invoice).permit(:client_id, :user_id, :invoice_date, :invoice_number,:description, :order_number, :currency_id, :bank_id, :invoice_category_id, :deleted, :is_proforma, :sent, :paid, :product_pricing, :unit_price, :quantity, :special_days, invoice_items_attributes: [:id, :item_code, :description, :quantity, :unit_price, :vat_type_id], license_attributes: [:id, :client_id, :invoice_id, :license_category_id, :license_option_id, :renewal_date, :auto_renewal, :amount, :quantity, :special_days, :is_special], branch_ids: [])
    end

    def credit_note_params
      params.require(:credit_note).permit(:invoice_id, :transaction_date, :document_number, :reference_number, :reason, :invoice_amount, :user_id, :tenant_id)
    end

    def next_invoice_number
      config_key = ConfigKey.find_by(name: 'Invoice No.')
      setting = tenant.system_settings.find_by(config_key_id: config_key.id)

      return unless setting

      last = tenant.invoices.order(invoice_number: :asc).all_sales.last

      last.nil? ? setting.config_value : last.invoice_number.next
    end

end
