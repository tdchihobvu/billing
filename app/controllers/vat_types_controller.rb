class VatTypesController < ApplicationController
  before_action :set_vat_type, only: %i[ show edit update destroy ]

  # GET /vat_types
  def index
    @vat_types = VatType.all
  end

  # GET /vat_types/1
  def show
  end

  # GET /vat_types/new
  def new
    @vat_type = VatType.new
  end

  # GET /vat_types/1/edit
  def edit
  end

  # POST /vat_types
  def create
    @vat_type = VatType.new(vat_type_params)

    if @vat_type.save
      redirect_to @vat_type, notice: "Vat type was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /vat_types/1
  def update
    if @vat_type.update(vat_type_params)
      redirect_to @vat_type, notice: "Vat type was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /vat_types/1
  def destroy
    @vat_type.destroy!
    redirect_to vat_types_url, notice: "Vat type was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vat_type
      @vat_type = VatType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def vat_type_params
      params.require(:vat_type).permit(:name, :rate)
    end
end
