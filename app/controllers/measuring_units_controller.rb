class MeasuringUnitsController < ApplicationController
  before_action :set_measuring_unit, only: %i[ show edit update destroy ]

  # GET /measuring_units
  def index
    @measuring_units = MeasuringUnit.all
  end

  # GET /measuring_units/1
  def show
  end

  # GET /measuring_units/new
  def new
    @measuring_unit = MeasuringUnit.new
  end

  # GET /measuring_units/1/edit
  def edit
  end

  # POST /measuring_units
  def create
    @measuring_unit = MeasuringUnit.new(measuring_unit_params)

    if @measuring_unit.save
      redirect_to @measuring_unit, notice: "Measuring unit was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /measuring_units/1
  def update
    if @measuring_unit.update(measuring_unit_params)
      redirect_to @measuring_unit, notice: "Measuring unit was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /measuring_units/1
  def destroy
    @measuring_unit.destroy!
    redirect_to measuring_units_url, notice: "Measuring unit was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_measuring_unit
      @measuring_unit = MeasuringUnit.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def measuring_unit_params
      params.require(:measuring_unit).permit(:name, :symbol)
    end
end
