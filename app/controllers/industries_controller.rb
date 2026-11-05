class IndustriesController < ApplicationController
  before_action :set_industry, only: %i[ show edit update destroy ]

  # GET /industries
  def index
    @industries = Industry.where(tenant_id: tenant.id)
  end

  # GET /industries/1
  def show
  end

  # GET /industries/new
  def new
    @industry = Industry.new
    @industry.tenant_id = tenant.id
  end

  # GET /industries/1/edit
  def edit
    if @industry.tarrif.nil?
      @industry.build_tarrif(tenant_id: tenant.id)
    end
  end

  # POST /industries
  def create
    @industry = Industry.new(industry_params)
    if @industry.save
      if @industry.tarrif.nil?
        Tarrif.create(tenant_id: tenant.id, industry_id: @industry.id, name: @industry.name, amount: @industry.amount)
      end
      redirect_to industries_url, notice: "Industry was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /industries/1
  def update
    if @industry.update(industry_params)
      if @industry.tarrif.nil?
        Tarrif.create(tenant_id: tenant.id, industry_id: @industry.id, name: @industry.name, amount: @industry.amount)
      end
      redirect_to @industry, notice: "Industry was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /industries/1
  def destroy
    @industry.destroy!
    redirect_to industries_url, notice: "Industry was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_industry
      @industry = Industry.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def industry_params
      params.require(:industry).permit(:name, :tenant_id, :amount, tarrif_attributes: [:id, :industry_id, :tenant_id, :amount, :name])
    end
end
