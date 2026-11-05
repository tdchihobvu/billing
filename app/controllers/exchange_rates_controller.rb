class ExchangeRatesController < ApplicationController
  before_action :set_exchange_rate, only: %i[ show edit update destroy ]

  # GET /exchange_rates
  def index
    @exchange_rates = ExchangeRate.order(transaction_date: :desc).where(tenant_id: tenant.id)
    @exchange_rate = ExchangeRate.new
    @exchange_rate.transaction_date = Date.today
  end

  # GET /exchange_rates/1
  def show
  end

  # GET /exchange_rates/new
  def new
    @exchange_rate = ExchangeRate.new
  end

  # GET /exchange_rates/1/edit
  def edit
  end

  # POST /exchange_rates
  def create
    @exchange_rate = ExchangeRate.new(exchange_rate_params)
    @exchange_rate.user_id = current_user.id
    @exchange_rate.buying_rate = 1
    @exchange_rate.midrate = 1
    @exchange_rate.tenant_id = tenant.id
    if @exchange_rate.save
      @exchange_rate.update_currency
      redirect_to exchange_rates_url, notice: "Exchange rate was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /exchange_rates/1
  def update
    if @exchange_rate.update(exchange_rate_params)
      case exchange_rate_update_frequency
      when 'daily'
        Invoice.where(invoice_date: @exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
        Receipt.where(transaction_date: @exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
      when 'skip day'
        Invoice.where(invoice_date: (@exchange_rate.transaction_date - 1.day)..@exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
        Receipt.where(gtransaction_date: (@exchange_rate.transaction_date - 1.day)..@exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
      when 'weekly'
        puts("***** starting from #{@exchange_rate.transaction_date - 6.day}")
        Invoice.where(invoice_date: (@exchange_rate.transaction_date - 6.day)..@exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
        Receipt.where(transaction_date: (@exchange_rate.transaction_date - 6.day)..@exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
      when 'monthly'
        Invoice.where(invoice_date: (@exchange_rate.transaction_date - 1.month)..@exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
        Receipt.where(transaction_date: (@exchange_rate.transaction_date - 1.month)..@exchange_rate.transaction_date).update_all(rate: @exchange_rate.selling_rate)
      end
      @exchange_rate.update_currency
      redirect_to exchange_rates_url, notice: "Exchange rate was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /exchange_rates/1
  def destroy
    @exchange_rate.destroy!
    redirect_to exchange_rates_url, notice: "Exchange rate was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_exchange_rate
      @exchange_rate = ExchangeRate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def exchange_rate_params
      params.require(:exchange_rate).permit(:tenant_id, :currency_id, :transaction_date, :buying_rate, :midrate, :selling_rate, :user_id, :alternative_rate)
    end
end
