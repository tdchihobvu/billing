class TarrifsController < ApplicationController
  before_action :set_tarrif, only: %i[ show edit update destroy ]

  # GET /tarrifs
  def index
    @tarrifs = Tarrif.all
  end

  # GET /tarrifs/1
  def show
  end

  # GET /tarrifs/new
  def new
    @tarrif = Tarrif.new
  end

  # GET /tarrifs/1/edit
  def edit
  end

  # POST /tarrifs
  def create
    @tarrif = Tarrif.new(tarrif_params)
    @tarrif.tenant_id = tenant.id
    if @tarrif.save
      redirect_to tarrifs_url, notice: "Tarrif was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tarrifs/1
  def update
    if @tarrif.update(tarrif_params)
      redirect_to @tarrif, notice: "Tarrif was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tarrifs/1
  def destroy
    @tarrif.destroy!
    redirect_to tarrifs_url, notice: "Tarrif was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tarrif
      @tarrif = Tarrif.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tarrif_params
      params.require(:tarrif).permit(:industry_id, :name, :amount)
    end
end
