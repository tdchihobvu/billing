class TenantLocalesController < ApplicationController
  before_action :set_tenant_locale, only: %i[ show edit update destroy ]

  # GET /tenant_locales
  def index
    @tenant_locales = TenantLocale.all
  end

  # GET /tenant_locales/1
  def show
  end

  # GET /tenant_locales/new
  def new
    @tenant_locale = TenantLocale.new
  end

  # GET /tenant_locales/1/edit
  def edit
  end

  # POST /tenant_locales
  def create
    @tenant_locale = TenantLocale.new(tenant_locale_params)

    if @tenant_locale.save
      redirect_to @tenant_locale, notice: "Tenant locale was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tenant_locales/1
  def update
    if @tenant_locale.update(tenant_locale_params)
      redirect_to @tenant_locale, notice: "Tenant locale was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tenant_locales/1
  def destroy
    @tenant_locale.destroy!
    redirect_to tenant_locales_url, notice: "Tenant locale was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tenant_locale
      @tenant_locale = TenantLocale.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tenant_locale_params
      params.require(:tenant_locale).permit(:config_value, :config_key, :active)
    end
end
