require "application_system_test_case"

class PaymentFormsTest < ApplicationSystemTestCase
  setup do
    @payment_form = payment_forms(:one)
  end

  test "visiting the index" do
    visit payment_forms_url
    assert_selector "h1", text: "Payment forms"
  end

  test "should create payment form" do
    visit payment_forms_url
    click_on "New payment form"

    fill_in "Name", with: @payment_form.name
    click_on "Create Payment form"

    assert_text "Payment form was successfully created"
    click_on "Back"
  end

  test "should update Payment form" do
    visit payment_form_url(@payment_form)
    click_on "Edit this payment form", match: :first

    fill_in "Name", with: @payment_form.name
    click_on "Update Payment form"

    assert_text "Payment form was successfully updated"
    click_on "Back"
  end

  test "should destroy Payment form" do
    visit payment_form_url(@payment_form)
    click_on "Destroy this payment form", match: :first

    assert_text "Payment form was successfully destroyed"
  end
end
