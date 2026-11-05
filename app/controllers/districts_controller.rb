class DistrictsController < ApplicationController
  before_action :set_district, only: %i[ show edit update destroy ]

  # GET /districts
  def index
    @districts = District.all
  end

  # GET /districts/1
  def show
  end

  # GET /districts/new
  def new
    @district = District.new
  end

  # GET /districts/1/edit
  def edit
  end

  # POST /districts
  def create
    @district = District.new(district_params)

    if @district.save
      redirect_to @district, notice: "District was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /districts/1
  def update
    if @district.update(district_params)
      redirect_to @district, notice: "District was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /districts/1
  def destroy
    @district.destroy!
    redirect_to districts_url, notice: "District was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_district
      @district = District.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def district_params
      params.require(:district).permit(:region_id, :name)
    end
end
