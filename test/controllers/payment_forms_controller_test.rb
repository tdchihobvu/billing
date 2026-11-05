require "test_helper"

class PaymentFormsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @payment_form = payment_forms(:one)
  end

  test "should get index" do
    get payment_forms_url
    assert_response :success
  end

  test "should get new" do
    get new_payment_form_url
    assert_response :success
  end

  test "should create payment_form" do
    assert_difference("PaymentForm.count") do
      post payment_forms_url, params: { payment_form: { name: @payment_form.name } }
    end

    assert_redirected_to payment_form_url(PaymentForm.last)
  end

  test "should show payment_form" do
    get payment_form_url(@payment_form)
    assert_response :success
  end

  test "should get edit" do
    get edit_payment_form_url(@payment_form)
    assert_response :success
  end

  test "should update payment_form" do
    patch payment_form_url(@payment_form), params: { payment_form: { name: @payment_form.name } }
    assert_redirected_to payment_form_url(@payment_form)
  end

  test "should destroy payment_form" do
    assert_difference("PaymentForm.count", -1) do
      delete payment_form_url(@payment_form)
    end

    assert_redirected_to payment_forms_url
  end
end
