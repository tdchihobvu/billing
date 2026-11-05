class BanksController < ApplicationController
  before_action :set_bank, only: %i[ show edit update destroy ]

  # GET /banks
  def index
    @banks = tenant.banks
  end

  # GET /banks/1
  def show
  end

  # GET /banks/new
  def new
    @bank = Bank.new
    @bank.tenant_id = current_user.tenant_id
  end

  # GET /banks/1/edit
  def edit
  end

  # POST /banks
  def create
    @bank = Bank.new(bank_params)

    if @bank.save
      redirect_to @bank, notice: "Bank was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /banks/1
  def update
    if @bank.update(bank_params)
      redirect_to @bank, notice: "Bank was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /banks/1
  def destroy
    @bank.destroy!
    redirect_to banks_url, notice: "Bank was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bank
      @bank = Bank.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def bank_params
      params.require(:bank).permit(:tenant_id, :bank_name, :account_name, :account_number, :branch, :swift_code, :currency_id, :active, :description)
    end
end
