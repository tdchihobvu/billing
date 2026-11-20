class DevicesController < ApplicationController
  before_action :set_device, only: %i[ show edit update destroy ]

  # GET /devices
  def index
    # Only this company's devices (the list used to show every company's).
    @devices = Device.where(tenant_id: tenant.id).preload(:user, :regional_office)
  end

  # GET /devices/1
  def show
  end

  # GET /devices/new
  def new
    @device = Device.new
  end

  # GET /devices/1/edit
  def edit
  end

  # POST /devices
  def create
    @device = Device.new(device_params)
    @device.tenant_id = tenant.id
    @device.access_token = Device.generate_token
    @device.terminal_id = Device.generate_device_id
    if @device.save
      redirect_to @device, notice: "Device was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /devices/1
  def update
    if @device.update(device_params)
      redirect_to @device, notice: "Device was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /devices/1
  def destroy
    @device.destroy!
    redirect_to devices_url, notice: "Device was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_device
      @device = Device.where(tenant_id: tenant.id).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def device_params
      params.require(:device).permit(:name, :serial_number, :model, :active, :user_id, :access_token, :regional_office_id)
    end
end
