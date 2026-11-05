class LicenseOptionsController < ApplicationController
  before_action :set_license_option, only: %i[ show edit update destroy ]

  # GET /license_options
  def index
    @license_options = LicenseOption.all
  end

  # GET /license_options/1
  def show
  end

  # GET /license_options/new
  def new
    @license_option = LicenseOption.new
  end

  # GET /license_options/1/edit
  def edit
  end

  # POST /license_options
  def create
    @license_option = LicenseOption.new(license_option_params)

    if @license_option.save
      redirect_to @license_option, notice: "License option was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /license_options/1
  def update
    if @license_option.update(license_option_params)
      redirect_to @license_option, notice: "License option was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /license_options/1
  def destroy
    @license_option.destroy!
    redirect_to license_options_url, notice: "License option was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_license_option
      @license_option = LicenseOption.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def license_option_params
      params.require(:license_option).permit(:name, :months, :active, :count_by)
    end
end
