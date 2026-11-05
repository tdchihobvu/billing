class RegionalOfficesController < ApplicationController
  before_action :set_regional_office, only: %i[ show edit update destroy ]

  # GET /regional_offices
  def index
    @regional_offices = RegionalOffice.all
  end

  # GET /regional_offices/1
  def show
  end

  # GET /regional_offices/new
  def new
    @regional_office = RegionalOffice.new
  end

  # GET /regional_offices/1/edit
  def edit
  end

  # POST /regional_offices
  def create
    @regional_office = RegionalOffice.new(regional_office_params)
    @regional_office.tenant_id = tenant.id
    if @regional_office.save
      redirect_to @regional_office, notice: "Regional office was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /regional_offices/1
  def update
    if @regional_office.update(regional_office_params)
      redirect_to @regional_office, notice: "Regional office was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /regional_offices/1
  def destroy
    @regional_office.destroy!
    redirect_to regional_offices_url, notice: "Regional office was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regional_office
      @regional_office = RegionalOffice.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def regional_office_params
      params.require(:regional_office).permit(:region_id, :name)
    end
end
