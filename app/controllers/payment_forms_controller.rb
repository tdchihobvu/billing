class PaymentFormsController < ApplicationController
  before_action :set_payment_form, only: %i[ show edit update destroy ]

  # GET /payment_forms
  def index
    @payment_forms = PaymentForm.all
  end

  # GET /payment_forms/1
  def show
  end

  # GET /payment_forms/new
  def new
    @payment_form = PaymentForm.new
  end

  # GET /payment_forms/1/edit
  def edit
  end

  # POST /payment_forms
  def create
    @payment_form = PaymentForm.new(payment_form_params)

    if @payment_form.save
      redirect_to @payment_form, notice: "Payment form was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /payment_forms/1
  def update
    if @payment_form.update(payment_form_params)
      redirect_to @payment_form, notice: "Payment form was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /payment_forms/1
  def destroy
    @payment_form.destroy!
    redirect_to payment_forms_url, notice: "Payment form was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_payment_form
      @payment_form = PaymentForm.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def payment_form_params
      params.require(:payment_form).permit(:name)
    end
end
