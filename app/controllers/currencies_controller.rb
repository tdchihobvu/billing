class CurrenciesController < ApplicationController
  before_action :set_currency, only: %i[ show edit update destroy ]

  # GET /currencies
  def index
    @currencies = Currency.all
  end

  # GET /currencies/1
  def show
  end

  # GET /currencies/new
  def new
    @currency = Currency.new
  end

  # GET /currencies/1/edit
  def edit
  end

  # POST /currencies
  def create
    @currency = Currency.new(currency_params)

    if @currency.save
      redirect_to @currency, notice: "Currency was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /currencies/1
  def update
    if @currency.update(currency_params)
      redirect_to @currency, notice: "Currency was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /currencies/1
  def destroy
    @currency.destroy!
    redirect_to currencies_url, notice: "Currency was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_currency
      @currency = Currency.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def currency_params
      params.require(:currency).permit(:name, :symbol, :origin, :active, :trcode, :account_reference, payment_form_ids: [])
    end
end
