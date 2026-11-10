class ReceiptsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_receipt, only: %i[ show edit update destroy print ]

  # Shifts actions
  def shifts
    @shifts = tenant.shifts.active.order('start_time Asc, end_time Asc').includes(:device)
  end

  # GET /receipts
  def index
    @currencies = Currency.all

    @receipts = current_user.tenant.receipts
                             .active
                             .where(transaction_date: Date.current.all_month)
                             .includes(:client, :payment_form, :currency)
                             .order(transaction_date: :desc).limit(50)
  end



  # GET /receipts/1
  def show
  end

  # GET /receipts/new
  def new
    @clients = Client.search(params[:search])
  end

  def record_receipt
    @client = Client.find(params[:client_id])
    @clients = Client.where(id: @client.id)
    # @client.update_client_balances
    as_at = Date.today
    @receipt = Receipt.new
    @receipt.client_id = @client.id
    @receipt.transaction_date = Date.today
    @receipt.user_id = current_user.id
    @receipt.amount = @client.balance
    @receipt.transaction_source = default_transaction_source
    @invoices = []    
  end

  def invoices
    # get the member
    @target = params[:target]
    @client = Client.find(params[:client])
    @invoices = @client.invoices.active.order('invoice_number asc')
    puts("tiri tiiii #{@client.name}")
    respond_to do |format|
      format.turbo_stream
    end
  end

  # GET /receipts/1/edit
  def edit
  end

  # POST /receipts
  def create
    @receipt = Receipt.new(receipt_params)
    @receipt.tenant_id = tenant.id
    @client = Client.find_by(id: params[:receipt][:client_id])
    @clients = Client.where(id: @client.id)

    rec_no = Receipt.generate_receipt_number(current_user.tenant)

    @receipt.reference_number = rec_no
    @receipt.source_reference = rec_no

    if @receipt.save
      @receipt.update!(actual_paid: @receipt.amount_paid)

      @receipt.invoice&.update_balance

      redirect_to @receipt,
                  notice: "Receipt was successfully created."
    else
      Rails.logger.info "RECEIPT ERRORS: #{@receipt.errors.full_messages}"

      render :record_receipt, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /receipts/1
  def update
    if @receipt.update(receipt_params)
      invoice = Invoice.find(@receipt.invoice_id)
      unless invoice.nil?
        invoice.update_attribute(:last_payment_update, @receipt.updated_at + 2.hours)
      end
      redirect_to @receipt, notice: "Receipt was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def print 
    pdf = Prawn::Document.new 
    # Start of PDF

      pdf.image "#{Rails.root}/public/tenant_logo/#{logo_path}", height: 100

      pdf.draw_text "RECEIPT", :at => [400,700], style: :bold, size: 22

      pdf.bounding_box([400,690], width: 330, height: 110, :pad => 2) do 
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
        # pdf.indent(0,0) do # left and right padding
        #   pdf.text "VAT Number: #{tenant.vat_number}", size: 9, style: :bold
        #   pdf.text "TIN Number: #{tenant.bp_number}", size: 9, style: :bold
        # end
      end

      pdf.stroke_horizontal_rule
      pdf.move_down 20

      pdf.bounding_box([0,565], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 5
        pdf.text "Receipt Details", align: :left, size: 12, style: :bold, :color => "A8A8A8"
      end

      pdf.bounding_box([320,570], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 5
        pdf.indent 0,0 do
          pdf.text "Receipt No: ", align: :right, size: 9
          pdf.text "#{@receipt.reference_number}", align: :right, size: 10, style: :bold
          pdf.fill_color "ffffff"
          pdf.text ".", align: :right, size: 7
          pdf.fill_color "222222"
          pdf.text "Date: ", align: :right, size: 9
          pdf.text "#{@receipt.transaction_date.strftime("%d/%m/%Y")}", align: :right, size: 10
        end
      end

      pdf.bounding_box([0,480], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 5
        pdf.text "Client Details", align: :left, size: 12, style: :bold, :color => "A8A8A8"
      end

      pdf.bounding_box([320,485], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 5
        pdf.text "#{@receipt.client.name.upcase}", align: :right, size: 9, style: :bold
        pdf.indent 0,0 do
          pdf.text "#{@receipt.client.address_1}", align: :right, size: 9
          pdf.text "#{@receipt.client.address_2} #{@receipt.client.location}", align: :right, size: 9
          pdf.text "#{@receipt.client.city}, #{@receipt.client.country}", align: :right, size: 9
          pdf.text "Customer VAT No: #{@receipt.client.vat_number}", align: :right, size: 9
          pdf.text "Customer TIN No: #{@receipt.client.bp_number}", align: :right, size: 9
        end
      end
      # pdf.stroke_horizontal_rule

      pdf.bounding_box([0,380], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 5
        pdf.text "Payment Details", align: :left, size: 12, style: :bold, :color => "A8A8A8"
      end

      pdf.bounding_box([320,380], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 5
        pdf.indent 0,0 do
          pdf.text "Payment Method: #{@receipt.payment_form.name}", align: :right, size: 10
          pdf.fill_color "ffffff"
          pdf.text ".", align: :right, size: 9
          pdf.fill_color "222222"
          pdf.text "#{@receipt.description}", align: :right, size: 10
        end
      end

      pdf.stroke_horizontal_rule

      pdf.bounding_box([0,300], width: 200, height: 95, :pad => 2) do 
        pdf.move_down 35
        pdf.text "Amount Paid", align: :left, size: 12, style: :bold, :color => "A8A8A8"
      end

      pdf.bounding_box([450,295], width: 200, height: 125, :pad => 2) do 
        pdf.move_down 35
        pdf.text "#{number_to_currency(@receipt.amount, unit: "#{@receipt.currency.symbol} ")}", align: :left, size: 12, style: :bold
      end

      pdf.text "Thank you for your payment!", align: :center, :color => "A8A8A8"

      pdf.number_pages "Receipt ##{@receipt.reference_number} | Transaction By #{@receipt.user.user_fullname} | Generated from Aibes Billing System ver7.1", :start_count_at => 0, :page_filter => :all, :at => [pdf.bounds.right - 300, 8], :align => :right, :size => 7      
      pdf.number_pages "A product of Dapsoft Solutions | <page> of <total>", :start_count_at => 0, :page_filter => :all, :at => [pdf.bounds.right - 200, 0], :align => :right, :size => 5.5  

      # End of PDF
      send_data(pdf.render, 
        filename: "#{@receipt.client.name} - #{@receipt.reference_number}.pdf",
        type: 'application/pdf', disposition: 'inline')   
  end

  # DELETE /receipts/1
  def destroy
    ActiveRecord::Base.transaction do
      @receipt.update!(deleted: true)
      @receipt.invoice&.update_balance
    end

    redirect_to receipts_url,
                notice: "Receipt void successful.",
                status: :see_other
  end

  def close_shift
    shift = Shift.find_by(shift_id: params[:shiftId], username: params[:username])
    if shift  
      if shift.close_shift(params[:end_time])
        flash[:notice] = "Shift successfully closed at #{shift.end_time}"
      else
        flash[:notice] = "Ooops! There was an error when trying to close your shift."
      end
    else
      flash[:notice] = "Your shift does not exists"
    end
    redirect_to shifts_receipts_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_receipt
      @receipt = Receipt.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def receipt_params
      params.require(:receipt).permit(:client_id, :currency_id, :payment_form_id, :user_id, :transaction_date, :reference_number, :amount, :rate, :description, :deleted, :invoice_id, :transaction_source)
    end
end
