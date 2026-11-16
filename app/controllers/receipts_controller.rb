class ReceiptsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_receipt, only: %i[ show edit update destroy print ]
  before_action :set_form_client, only: %i[ edit update ]

  # Shifts actions
  def shifts
    @shifts = tenant.shifts.active.order('start_time Asc, end_time Asc').includes(:device)
  end

  # GET /receipts
  def index
    @currencies = Currency.order(:name)
    @payment_forms = PaymentForm.order(:name)
    @users = tenant.users.order(:firstname, :lastname)
    scope = current_user.tenant.receipts.active
    @unlinked = params[:unlinked] == "1"
    scope = scope.where(invoice_id: nil, transaction_date: 30.days.ago.beginning_of_day..Time.current.end_of_day) if @unlinked
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(currency_id: params[:currency_id]) if params[:currency_id].present?
    scope = scope.where(payment_form_id: params[:payment_form_id]) if params[:payment_form_id].present?
    if params[:q].present?
      scope = TextSearch.apply(scope.joins(:client), params[:q], %w[clients.name clients.client_account_number receipts.reference_number])
    end
    @count = scope.count
    @totals = scope.joins(:currency).group("currencies.name").sum(:amount)
    @per_page = 50
    @page = [params[:page].to_i, 1].max
    @pages = [(@count / @per_page.to_f).ceil, 1].max
    @receipts = scope.includes(:client, :payment_form, :currency, :user, :invoice)
                     .order(transaction_date: :desc, reference_number: :desc)
                     .offset((@page - 1) * @per_page).limit(@per_page)
  end

  # GET /receipts/1
  def show
  end

  # GET /receipts/new
  def new
    @clients = if params[:search].present?
                 TextSearch.apply(tenant.clients, params[:search], %w[clients.name clients.trading_name clients.client_account_number clients.city clients.location]).order(:name).limit(50)
               else
                 []
               end
  end

  def record_receipt
    @client = tenant.clients.find(params[:client_id])
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
    @client = tenant.clients.find(params[:client])
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
    @client = tenant.clients.find_by(id: params[:receipt][:client_id])
    @clients = @client ? Client.where(id: @client.id) : Client.none
    # The receipt form is built around one client; without one, go back and pick it.
    return redirect_to(new_receipt_path, alert: "Choose the client first, then record the receipt.") unless @client

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

      # Re-show the receipt form (with errors) instead of the client search page.
      # Force HTML: Turbo submits as TURBO_STREAM, and new.turbo_stream.erb renders nothing.
      @invoices = []
      render :record_receipt, status: :unprocessable_entity, formats: [:html]
    end
  end

  # PATCH/PUT /receipts/1
  def update
    if @receipt.update(receipt_params)
      invoice = Invoice.find_by(id: @receipt.invoice_id)
      unless invoice.nil?
        invoice.update_attribute(:last_payment_update, @receipt.updated_at + 2.hours)
      end
      redirect_to @receipt, notice: "Receipt was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def print
    pdf = ReceiptPdf.new(@receipt, tenant: tenant, logo_file: logo_path, brand: helpers.brand_color,
                                   user_title: helpers.default_user_title)
    send_data(pdf.render,
              filename: "#{@receipt.client.name} - #{@receipt.reference_number}.pdf",
              type: "application/pdf", disposition: "inline")
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
    def set_form_client
      @client = @receipt.client
      @clients = Client.where(id: @client.id)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_receipt
      @receipt = Receipt.where(tenant_id: tenant.id).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def receipt_params
      params.require(:receipt).permit(:client_id, :currency_id, :payment_form_id, :user_id, :transaction_date, :reference_number, :amount, :rate, :description, :deleted, :invoice_id, :transaction_source)
    end
end
