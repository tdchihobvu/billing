class ClientTypesController < ApplicationController
  before_action :set_client_type, only: %i[ show edit update destroy ]

  # GET /client_types
  def index
    @client_types = ClientType.all
  end

  # GET /client_types/1
  def show
  end

  # GET /client_types/new
  def new
    @client_type = ClientType.new
  end

  # GET /client_types/1/edit
  def edit
  end

  # POST /client_types
  def create
    @client_type = ClientType.new(client_type_params)

    if @client_type.save
      redirect_to @client_type, notice: "Client type was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /client_types/1
  def update
    if @client_type.update(client_type_params)
      redirect_to @client_type, notice: "Client type was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /client_types/1
  def destroy
    @client_type.destroy!
    redirect_to client_types_url, notice: "Client type was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client_type
      @client_type = ClientType.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_type_params
      params.require(:client_type).permit(:name)
    end
end
