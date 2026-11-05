class GoodsReceivedsController < ApplicationController
  before_action :set_goods_received, only: %i[ show edit update destroy ]

  # GET /goods_receiveds
  def index
    @goods_receiveds = GoodsReceived.all
  end

  # GET /goods_receiveds/1
  def show
  end

  # GET /goods_receiveds/new
  def new
    @goods_received = GoodsReceived.new
    @goods_received.user_id = current_user
    last = tenant.goods_receiveds[-1]
    if last.nil?
      @goods_received.grv_number = "001"
    else
      @goods_received.grv_number = last.grv_number.next
    end

    10.times {@goods_received.goods_received_items.build}
  end

  # GET /goods_receiveds/1/edit
  def edit
  end

  # POST /goods_receiveds
  def create
    @goods_received = GoodsReceived.new(goods_received_params)

    if @goods_received.save
      redirect_to @goods_received, notice: "Goods received was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /goods_receiveds/1
  def update
    if @goods_received.update(goods_received_params)
      redirect_to @goods_received, notice: "Goods received was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /goods_receiveds/1
  def destroy
    @goods_received.destroy!
    redirect_to goods_receiveds_url, notice: "Goods received was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_goods_received
      @goods_received = GoodsReceived.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def goods_received_params
      params.require(:goods_received).permit(:grv_number, :ext_number, :supplier_id, :date_received, :user_id, :deleted, goods_received_items: [])
    end
end
