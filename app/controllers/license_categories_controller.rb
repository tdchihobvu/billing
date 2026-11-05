class LicenseCategoriesController < ApplicationController
  before_action :set_license_category, only: %i[ show edit update destroy ]

  # GET /license_categories
  def index
    @license_categories = LicenseCategory.all
  end

  # GET /license_categories/1
  def show
  end

  # GET /license_categories/new
  def new
    @license_category = LicenseCategory.new
  end

  # GET /license_categories/1/edit
  def edit
  end

  # POST /license_categories
  def create
    @license_category = LicenseCategory.new(license_category_params)

    if @license_category.save
      redirect_to @license_category, notice: "License category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /license_categories/1
  def update
    if @license_category.update(license_category_params)
      redirect_to @license_category, notice: "License category was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /license_categories/1
  def destroy
    @license_category.destroy!
    redirect_to license_categories_url, notice: "License category was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_license_category
      @license_category = LicenseCategory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def license_category_params
      params.require(:license_category).permit(:name, :description)
    end
end
