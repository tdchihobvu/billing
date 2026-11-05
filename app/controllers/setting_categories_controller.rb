class SettingCategoriesController < ApplicationController
  before_action :set_setting_category, only: %i[ show edit update destroy ]

  # GET /setting_categories
  def index
    @setting_categories = SettingCategory.all
  end

  # GET /setting_categories/1
  def show
  end

  # GET /setting_categories/new
  def new
    @setting_category = SettingCategory.new
  end

  # GET /setting_categories/1/edit
  def edit
  end

  # POST /setting_categories
  def create
    @setting_category = SettingCategory.new(setting_category_params)

    if @setting_category.save
      redirect_to @setting_category, notice: "Setting category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /setting_categories/1
  def update
    if @setting_category.update(setting_category_params)
      redirect_to @setting_category, notice: "Setting category was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /setting_categories/1
  def destroy
    @setting_category.destroy!
    redirect_to setting_categories_url, notice: "Setting category was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting_category
      @setting_category = SettingCategory.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def setting_category_params
      params.require(:setting_category).permit(:name)
    end
end
