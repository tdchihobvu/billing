class TenantsController < ApplicationController
  before_action :set_tenant, only: %i[ show edit update destroy settings ]

  # GET /tenants or /tenants.json
  def index
    @tenants = Tenant.where(id: tenant)
  end

  # GET /tenants/1 or /tenants/1.json
  def show
  end

  # GET /tenants/new
  def new
    @tenant = Tenant.new
  end

  # GET /tenants/1/edit
  def edit
  end

  # POST /tenants or /tenants.json
  def create
    @tenant = Tenant.new(tenant_params)

    respond_to do |format|
      if @tenant.save
        format.html { redirect_to tenant_url(@tenant), notice: "Tenant was successfully created." }
        format.json { render :show, status: :created, location: @tenant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tenant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tenants/1 or /tenants/1.json
  def update
    respond_to do |format|
      if @tenant.update(tenant_params)
        format.html {   redirect_to(params[:return_to].presence || system_settings_path, notice: "System settings were successfully updated.") }
        format.json { render :show, status: :ok, location: @tenant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tenant.errors, status: :unprocessable_entity }
      end
    end
  end

  def settings
    ConfigKey.all.each do |config_key|
      @tenant.system_settings.find_or_initialize_by(
        config_key_id: config_key.id
      )
    end
  end

  # DELETE /tenants/1 or /tenants/1.json
  def destroy
    # @tenant.destroy!

    # respond_to do |format|
    #   format.html { redirect_to tenants_url, notice: "Tenant was successfully destroyed." }
    #   format.json { head :no_content }
    # end
    redirect_to tenants_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tenant
      @tenant = Tenant.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tenant_params
      params.require(:tenant).permit(:tenant_category_id, :company_name, :trading_name, :registration_number, :bp_number, :vat_number, :address_1, :address_2, :location, :city, :country, :website, :info_email, :sales_email, :mobile_1, :mobile_2, :phone_1, :phone_2, :fax_number, :active, system_settings_attributes: [:id, :config_key_id, :tenant_id, :config_value], system_module_ids: [])
    end
end
