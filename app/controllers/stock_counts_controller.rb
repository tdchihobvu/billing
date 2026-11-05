class StockCountsController < ApplicationController
  before_action :set_stock_count, only: %i[ show edit update destroy ]

  # GET /stock_counts
  def index
    @stock_counts = StockCount.all
    @stock_count = StockCount.new
    @stock_count.transaction_date = Date.today
  end

  # GET /stock_counts/1
  def show
  end

  # GET /stock_counts/new
  def new
    @stock_count = StockCount.new
  end

  # GET /stock_counts/1/edit
  def edit
  end

  # POST /stock_counts
  def create
    @stock_count = StockCount.new(stock_count_params)

    if @stock_count.save
      redirect_to stock_counts_url, notice: "Stock count was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stock_counts/1
  def update
    if @stock_count.update(stock_count_params)
      redirect_to @stock_count, notice: "Stock count was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /stock_counts/1
  def destroy
    @stock_count.destroy!
    redirect_to stock_counts_url, notice: "Stock count was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stock_count
      @stock_count = StockCount.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stock_count_params
      params.require(:stock_count).permit(:product_name, :barcode, :quantity, :transaction_date)
    end
end
